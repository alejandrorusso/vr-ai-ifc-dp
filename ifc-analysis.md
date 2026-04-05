# Comparative IFC Analysis: `ai-labels` vs. Asbestos / HiStar / Flume

> This analysis is grounded in a direct reading of the source code:
> `ifc/ifc_label.h`, `ifc/ifc.bpf.c`, `tests/`, and the spec documents
> in `specs/`. Where the code diverges from the spec, the code takes precedence.

## Background on the Reference Systems

| System | Venue | Approach |
|--------|-------|----------|
| **Asbestos** (Efstathopoulos et al.) | SOSP 2005 | New OS (Oasis); labels as sets of categories; per-process send/receive labels |
| **HiStar** (Zeldovich et al.) | OSDI 2006 | New OS kernel; labels as integer-vectors over categories; all objects labeled |
| **Flume** (Krohn et al.) | SOSP 2007 | Modified Linux; decentralized IFC; (secrecy, integrity) tag-set pairs; explicit privilege tokens |

---

## 1. Label Format

### Prior work

All three systems use **abstract symbolic labels** independent of the filesystem:

- **Asbestos**: label = set of `(category, color)` pairs; each process has a separate *send label* and *receive label*
- **HiStar**: label = map from category → taint level ∈ {0, 1, 2, 3}; stored in kernel objects
- **Flume**: label = pair `(S, I)` where S is a secrecy tag-set and I is an integrity tag-set; tags are opaque integers minted by principals

Labels and filesystem permissions are **orthogonal** in all three: a file carries both POSIX permissions (for DAC) and a separate IFC label (for MAC). Label storage requires additional kernel data structures.

### ai-labels: label IS the POSIX permission triple

The label is defined in `ifc_label.h` as:

```c
struct ifc_label {
    __u32            uid;    /* owner identity */
    __u32            gid;    /* group identity */
    struct ifc_perms user;   /* r,w,x bits for owner */
    struct ifc_perms group;  /* r,w,x bits for group */
    struct ifc_perms other;  /* r,w,x bits for others */
};
```

File labels are constructed directly from kernel inode metadata (`ifc_label_from_mode`, `ifc_label.h:93`):

```c
static inline void ifc_label_from_mode(struct ifc_label *l,
                       __u16 mode, __u32 uid, __u32 gid)
{
    l->uid = uid; l->gid = gid;
    l->user.read  = !!(mode & 0400);
    ...
}
```

No new label vocabulary, no extra storage, no label/permission duality to maintain. Every existing filesystem is already labeled. This is a fundamental deployment advantage over all three prior systems.

### Two-level identity lattice

The uid dimension is implemented as (`ifc_label.h:110`):

```c
#define NOBODY_UID  65534U   /* bottom element — join identity */
#define LLM_UID     65533U   /* top element — manyuser */

static inline __u32 ifc_uid_join(__u32 a, __u32 b)
{
    if (a == NOBODY_UID) return b;
    if (b == NOBODY_UID) return a;
    return (a == b) ? a : LLM_UID;
}
```

The lattice is: `⊥ (nobody=65534) < specific_uid < manyuser (65533)`.

**Root is not part of the lattice algebra.** Root processes are excluded at every hook entry (`if uid==0: return 0`), but root-*owned files* do enter the join. Since `uid=0 ≠ NOBODY_UID=65534`, reading a root-owned file from a non-root process produces `ifc_uid_join(alice, 0) = LLM_UID`. This means any non-excepted, non-executable, root-owned file escalates the reading process to `manyuser:manygroup`. The `--except=` mechanism and the executable-file skip (see §3) exist in large part to handle this.

In Flume/Asbestos/HiStar, the label of a process that reads data from two principals carries both tags simultaneously (set union), growing unboundedly. Here the identity collapses immediately to a single sentinel — bounded, constant-space representation of multi-principal provenance.

### Monotonicity invariant (design-level only)

The spec (`specs/labels.md`) requires `other ≤ group ≤ user` for all permission bits as a label well-formedness invariant. This rules out paradoxical POSIX permissions and enables inclusive reasoning. However, **this invariant is not enforced in the BPF code**: `ifc_label_from_mode` reads the raw mode bits without validation. It is a design-time assumption, not a runtime check.

---

## 2. Enforcement Mode

This is the most operationally significant fact about the current implementation.

The BPF file header states explicitly (`ifc.bpf.c:31`):

```
* Enforcement policy (only-log mode):
*   No hook ever returns -EACCES.  Every event that would previously have
*   been denied is instead emitted to the log_events ring buffer.
```

This is confirmed throughout `ifc_file_permission`: every code path returns 0. Write violations are **logged** (`IFC_EVT_WRITE_VIOL`) but **not blocked**. The architecture doc's claim that existing-file violations return `-EACCES` does not match the code.

The only "enforcement" action that modifies the system state is **auto-relabeling of newly created files** via the ring buffer: when a tainted process creates a new file whose default mode would be too permissive, a `relabel_event` is submitted to userspace, and the loader calls `chmod()` asynchronously. This is the one place where the system acts beyond logging.

**Implication for the IFC novelty framing**: the system is best understood as an IFC *monitor* — it tracks and logs information flows accurately, and it tightens the labels of new files. It is a research prototype, not a fully enforcing MAC system. This is different from Asbestos, HiStar, and Flume, which all block disallowed flows.

---

## 3. Taint Propagation

### Full join on read (confirmed)

`ifc_file_open` (non-sleepable, `ifc.bpf.c:588`) applies an unconditional full join for every qualifying file open:

```c
ifc_label_join(&new_label, proc_label, &file_label);
*proc_label = new_label;
```

Qualifying means: not root process, regular file, no executable bits, not in exception list, opened for reading.

The join computes (`ifc_label.h:130`):
- uid: `ifc_uid_join(proc.uid, file.uid)` — same → same, bottom → other, different → manyuser
- gid: `ifc_gid_join(proc.gid, file.gid)` — same logic
- all 9 permission bits: bitwise AND (intersection, most restrictive wins)

### Others-as-declassifier rule: in spec, not in code

The architecture doc and `specs/ifc.md` describe a differentiated propagation rule: when `u_f ≠ u_p` AND `g_f ≠ g_p` AND `file.other.read = 1`, only the `other` permission bits should be tightened, preserving the process's uid, gid, and user/group permissions.

**This rule is not implemented in `ifc.bpf.c`.** The `ifc_file_open` hook always calls `ifc_label_join` with no conditional on world-readability. Reading a world-readable file from a completely different owner will escalate the process identity to `manyuser:manygroup` and tighten all permission bits — the same as reading any other file.

No test in the test suite covers this rule (the tests confirm full-join behavior throughout). It remains a spec-level design choice, not yet implemented.

This has significance for the anti-creep discussion: the "implicit declassification via world-readability" claimed as a novelty exists as a design intent but does not currently execute.

### Executable file skip (implicit exception, confirmed)

`ifc_file_open` skips all files with any executable bit (`ifc.bpf.c:606`):

```c
if (i_mode & (S_IXUSR | S_IXGRP | S_IXOTH))
    return 0;
```

Reading a shell script, a binary, or any file with an executable bit does not update the process label. This is a broad implicit exception that handles a large fraction of root-owned system files (binaries in `/bin`, `/usr/bin`, etc. are world-executable). Combined with the `--except=` whitelist, it makes the system practical on a real Linux distribution.

No prior IFC system has this concept because they were not designed to run on top of an existing OS with its full file-permission ecosystem.

### exec() behavior: join, not reset (confirmed)

`bprm_committed_creds` (`ifc.bpf.c:453`) computes:

```c
ifc_label_init_with_creds(&l_init, new_uid, new_gid);   // all perms = 1

if (before.uid != 0) {
    ifc_label_join(&joined, &before, &l_init);  // join(old_label, L_init)
    *label = joined;
} else {
    *label = l_init;                            // clean reset only when was root
}
```

Since `L_init` has all permission bits = 1, the AND leaves taint bits unchanged:
```
joined.perms = before.perms & 1 = before.perms   ← taint fully preserved
joined.uid   = join(before.uid, new_uid)          ← manyuser only if setuid exec
```

**exec does not reset the label.** Taint accumulated before exec survives it. The clean-reset branch fires exclusively for root-to-user transitions (e.g. `su`, setuid binaries) to prevent spurious `uid_join(0, user) = manyuser` escalation.

In **HiStar**, **Asbestos**, and **Flume**, labels also persist through exec. There is no novelty here relative to prior systems, and no reset mechanism in any of them.

### TTY writes as the anti-creep boundary (novel and confirmed)

The mechanism that keeps shell commands tractable is the **TTY-mediated parent taint** rule, implemented in `ifc_file_permission` (`ifc.bpf.c:708`). When a child process writes to a character device with TTY major numbers (4, 5, 136–143), the child's current label is joined into the parent's label:

```c
ifc_label_join(&taint_new, parent_cached, child_lbl);
bpf_map_update_elem(&pending_taint, &ppid, &taint_new, BPF_ANY);
```

This update happens **at write time**, not at child exit. The parent's label cache is updated before it can fork its next child.

**Why this enables clean shell operation**: bash accumulates taint only when a child writes to the terminal. If a command redirects to a file, bash stays clean. The next fork produces a clean child (inheriting bash's clean `L_init`), and exec confirms that clean state. The terminal output channel is the implicit declassification boundary — separating "private computation" (writes to files) from "shared output" (writes to TTY that the parent shell can act on).

Typical flow for `cat secret.txt > output.txt`:

| Step | Actor | Event | Label |
|------|-------|-------|-------|
| 1 | bash | starts | `L_init(alice,alice)` — all 1s |
| 2 | bash | forks child | child inherits `L_init` (bash is clean) |
| 3 | child | execs `cat` | `join(L_init, L_init) = L_init` |
| 4 | cat | reads `secret.txt` (600) | cat tainted |
| 5 | cat | writes to `output.txt` | WRITE_VIOL logged if file too permissive; chmod if new |
| 6 | cat | exits — no TTY write | bash label **unchanged** |

Contrast with `cat secret.txt` (output to terminal):

| Step | Actor | Event | Label |
|------|-------|-------|-------|
| 4 | cat | reads `secret.txt` | cat tainted |
| 5 | cat | writes to `/dev/pts/N` | **bash immediately tainted** via `pending_taint[ppid]` |
| 6 | bash | forks next command | next child inherits bash's taint |

**Chain propagation** for deeper process trees (bash→sh→cat) is handled via `ifc_task_free` (`ifc.bpf.c:1084`): when a process that had a child write to a TTY exits, its label is joined into its own parent's `pending_taint`, propagating taint up the tree iteratively.

No prior IFC system models the terminal as an IFC channel from child to parent. Asbestos, HiStar, and Flume were not designed around the shell execution model.

### Dynamic pipe labels with deferred reader taint (novel and confirmed)

Each pipe inode has a dynamic label in `pipe_labels` (a BPF hash map keyed by `{ino, dev}`), initialized lazily and updated on every write (`ifc.bpf.c:784`):

```c
if (pipe_lbl)
    ifc_label_join(&pipe_new, pipe_lbl, proc_lbl);
else
    pipe_new = *proc_lbl;
bpf_map_update_elem(&pipe_labels, &key, &pipe_new, BPF_ANY);
```

Readers join the pipe's accumulated label into their own label (`ifc.bpf.c:840`).

A further subtlety is the **deferred reader taint** (`pipe_pending_readers`, `ifc.bpf.c:195`): if a reader opens a pipe before the writer has written anything (and thus before the pipe has a label), the reader's PID is stored. When the writer subsequently writes, it taints the pending reader retroactively. This correctly handles single-read consumers like `head -1` that would otherwise miss the pipe label.

HiStar labels all kernel objects but the label is set at creation, not accumulated dynamically. Asbestos labels channels from the sender's send label at creation. Flume tracks labels per thread at endpoints. The accumulating join over all writers' lifetimes, plus the deferred-reader mechanism, is a distinct design.

---

## 4. Avoiding Label Creep

| Mechanism | Asbestos | HiStar | Flume | ai-labels |
|-----------|----------|--------|-------|-----------|
| Explicit declassification | Label-change requests | Gate objects (capabilities) | Privilege tokens (per-tag) | None |
| Implicit declassification (world-readable) | — | — | — | Designed but not yet in code |
| Label scope reset on exec | — | — | — | No (join, not reset) |
| Terminal-as-boundary | — | — | — | Yes (TTY taint rule) |
| Executable file skip | — | — | — | Yes |
| Static path whitelist | — | — | — | Yes (--except=) |
| Privilege revocation | Yes | Yes (gate) | Yes (token) | No |

### --except= whitelist with ancestor walk (novel and confirmed)

The `inode_is_excepted` helper (`ifc.bpf.c:246`) walks the kernel dentry tree upward from the opened file's inode, checking 6 levels (the file itself plus 5 ancestors) against the `inode_exceptions` BPF hash map. The walk is fully unrolled (no loop) to satisfy the BPF verifier:

```c
/* Level 0: file's own inode */
key.ino = BPF_CORE_READ(inode, i_ino);
if (bpf_map_lookup_elem(&inode_exceptions, &key)) return 1;

/* Levels 1–5: d_parent chain */
d = BPF_CORE_READ(d, d_parent);
key.ino = BPF_CORE_READ(d, d_inode, i_ino);
if (bpf_map_lookup_elem(&inode_exceptions, &key)) return 1;
/* ... repeated 4 more times ... */
```

Files more than 5 levels below an excepted root are not covered — requiring intermediate directories to be added explicitly to the exception map. The `ifc_loader_linux.sh` wrapper pre-populates:

| Path | Reason |
|------|--------|
| `/etc/`, `/usr/`, `/lib*/` | System config, libraries, locale data |
| `/proc/`, `/sys/`, `/run/` | Kernel virtual filesystems |
| `/boot/`, `/opt/`, `/snap/` | Boot images, optional packages |
| `/var/cache/`, `/var/lib/dpkg/`, `/var/lib/apt/` | Package manager state |
| Bash dotfiles (`~/.bashrc` etc.) | Startup files read by every shell |

This is necessary because a system deployed on an existing Linux distribution would immediately escalate to `manyuser:manygroup` upon reading any root-owned non-executable file outside these paths. Prior systems (Asbestos/HiStar/Flume) avoided this by controlling the entire software stack or running their own OS.

### No explicit declassification

Flume's privilege model (per-tag privilege tokens, revocable and transferable) is the most expressive anti-creep mechanism in prior work. HiStar uses gate objects; Asbestos uses label-change requests to authority. ai-labels has none of these. Declassification occurs only through:

1. The `--except=` whitelist (static, loader-configured)
2. The executable-file skip (implicit, based on file mode)
3. The TTY boundary (structural — redirect to file instead of terminal)

All three are coarser than a first-class privilege token, but require no new infrastructure beyond the loader configuration and standard shell redirections.

---

## 5. Write Enforcement

### Write condition: permission bits only (confirmed)

`ifc_can_write` (`ifc_label.h:155`) checks **only the 9 permission bits**, not uid or gid:

```c
static inline int ifc_can_write(const struct ifc_label *proc,
                const struct ifc_label *file)
{
    if (file->user.read   > proc->user.read)   return 0;
    /* ... all 9 bits ... */
    return 1;
}
```

A process with `manyuser` uid can write to an `alice`-owned file if the permission bits pass. The uid/gid in the process label is used only for **determining the ownership of newly created or relabeled files**, not for access decisions on existing ones.

### Auto-relabeling of new files (confirmed)

When a tainted process creates a new file and the write condition fails (`ifc_can_write` returns 0), the write is **allowed** and a `ifc_relabel_event` is submitted to the `relabel_events` ring buffer (`ifc.bpf.c:990`). The loader receives it and calls `chmod()` (and `chown()` when the identity is `manyuser`/`manygroup`) asynchronously. The tightest allowed mode is:

```c
static inline __u16 ifc_relabel_mode(const struct ifc_label *proc, __u16 file_mode)
{
    __u16 proc_bits = /* unpack proc label into a 9-bit mask */;
    return proc_bits & (file_mode & 0777);
}
```

This allows shell redirections (`> output.txt`) to work transparently: the file is created with the default umask mode, the write proceeds, and the IFC system tightens the mode after the fact. No prior IFC system has this pattern — they either block the write or require pre-labeling.

---

## 6. Implementation Platform (BPF-LSM on unmodified Linux)

| System | Implementation |
|--------|---------------|
| Asbestos | New OS (Oasis) |
| HiStar | New OS kernel from scratch |
| Flume | Kernel module + modified libc for Linux 2.6 |
| ai-labels | eBPF programs on LSM hooks, unmodified Linux 5.7+ |

The system requires no kernel patches, no new OS, no modified libc, no recompilation of applications. It loads at runtime via `bpf()` and unloads cleanly.

### Sleepable/non-sleepable BPF split (confirmed)

Two `file_open` hooks are used because of conflicting BPF constraints:
- `bpf_d_path()` (needed to capture paths for the async chmod) requires a sleepable BPF context
- `BPF_MAP_TYPE_TASK_STORAGE` (needed for per-task labels) is not available in sleepable programs on the target kernel

The sleepable hook (`lsm.s/file_open`) handles `O_CREAT` path capture; the non-sleepable hook (`lsm/file_open`) handles read-label tracking. This two-hook split is an implementation-level novelty driven by BPF kernel constraints.

Per-task label storage uses `BPF_MAP_TYPE_TASK_STORAGE`, which auto-frees on task exit — no `task_free` hook is needed for label cleanup (only for chain propagation and map maintenance).

### Unix socket label query

Unprivileged processes can query their own label via `/run/ifc/query.sock` using `SO_PEERCRED` authentication. The loader performs the privileged `BPF_MAP_TYPE_HASH` lookup (`task_label_cache`, a mirror of `TASK_STORAGE`) on behalf of the caller, avoiding the need for `CAP_BPF`.

---

## 7. Summary of Code-Confirmed Novelties

| Aspect | Status | Novelty vs. prior work |
|--------|--------|----------------------|
| Label format = POSIX permissions | **In code** | No separate label vocabulary; zero schema overhead |
| Two-level identity lattice (concrete → manyuser) | **In code** | Bounded, constant-space multi-principal tracking |
| Full join on read (unconditional) | **In code** | Standard; same direction as all prior systems |
| World-readable implicit declassification | **Spec only — not in code** | Designed but not yet implemented |
| exec() label join (not reset) | **In code** | Same behavior as all prior systems |
| TTY writes as anti-creep boundary | **In code** | Novel: terminal as IFC channel child→parent |
| Dynamic pipe labels with deferred reader taint | **In code** | Accumulating join; deferred-reader race handled |
| Executable file skip | **In code** | Implicit anti-creep for binaries/scripts |
| --except= ancestor walk (5-level BPF unroll) | **In code** | Practical whitelist for FHS paths |
| Log-only enforcement mode | **In code** | Monitor, not enforcer (unlike all prior systems) |
| Async chmod via ring buffer for new files | **In code** | Enables transparent shell redirections |
| BPF-LSM deployment (no kernel changes) | **In code** | No custom OS or kernel patches required |
| Write check on permission bits only (not uid/gid) | **In code** | Uid/gid only affects new-file labeling |

---

## 8. Limitations Relative to Prior Work

- **Log-only mode**: The system does not block disallowed writes. This is a prototype limitation, not a design choice — all three reference systems enforce their policies.
- **No explicit declassification**: Unlike Flume's privilege tokens, label creep in long-lived processes has no algebraic remedy. The TTY boundary and `--except=` whitelist are structural, not algebraic.
- **Others-as-declassifier not implemented**: The spec's differentiated propagation rule for world-readable files from unrelated owners is absent from the BPF code. Every read applies a full join.
- **Flat identity lattice**: The two-level identity (concrete → manyuser) loses precision immediately when any two distinct principals' data merges. Flume preserves the full tag set.
- **No integrity tracking**: Flume tracks `(secrecy, integrity)` pairs. There is no endorsement or integrity dimension here.
- **Root-owned files always escalate**: Because `uid_join(alice, 0) = manyuser` (root uid=0 ≠ nobody uid=65534), reading any non-excepted, non-executable root-owned file immediately escalates the process to `manyuser:manygroup`. The `--except=` and executable-skip mechanisms mitigate but do not eliminate this.
- **Flat directory model**: The spec acknowledges a flat directory assumption; full directory-tree IFC is identified as future work.
