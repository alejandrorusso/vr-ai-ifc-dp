# For the rest of the section

Paragraph about overall goal and architecture: 
- Our goal is an IFC enforcement that is \emph{fully backwards-compatible}:
no changes to existing AI agent code, no special planning language, deployable on
any standard Linux system.
- So we propose an OS-level enforcement for IFC, but different from previous work,  
  our novel system design will require no kernel patches (cite Flume), no new OS (cite HiStar and Asbestos), no modified libc (cite Flume), 
  and no recompilation of applications. 
- Furthermore, different from previous work also (HiStar, Flume, Asbestos),
  where IFC lables and filesystem permissions are **orthogonal**, we propose to
  infer IFC labels from POSIX permissions. No new label vocabulary, no extra
  storage, no label/permission duality to maintain. Every existing filesystem is
  already labeled. This is a fundamental deployment advantage over all three
  prior systems.
- Crafted the Paragraph so the novelty is clear. 

Paragraph about eBPF+
- IFC enforcement in Linux existed for a while as SELinux, but it is static,
  there is no floating-label IFC. 
- Introce eBPF as initially a virtual machine in the kernel to inspect packages,
  later it was extended and now it is capable to hook into many point in the
  kernel -- specially those use by the Linux Security Modules. 
- We propose a design to demonstrate that eBPF+ is enough to implement a
  OS-level floating-label IFC enforcement for AI agent loops. 
- In our initial prototype, our IFC floating-label monitor tracks and logs information flows, and it tightens the labels of new files -- 
  this is different from Asbestos, HiStar, and Flume, which all block disallowed flows while we try to adjust the labels instead.
 
 Paragraph on label propogation
 - Using eBPF+ we propose to hook essentially on syscalls to fork, execute,
   read, create and write files with some distinctions if the read/written 
   file is the terminal. 
 - Make a tikz diagram where the agent AI loop spawns shell commands where some 
   shell commands printed results on the terminal, read back by the AI agent,
   and another process just writes into a file. 


Description on the proposal on labels 
 - Introduce briefly the POSIX permission system for user, group, and others
   when it comes to read and write -- we will ignore execution.
 - Add a footnote saying that we consider  `other ≤ group ≤ user` since 
   linux permission system is not commulative (explain it in simple terms)
- We propose IFC labels to be a triple of the (role, permission bits) where 
  role is user, group, others, and permission is read or write. 
- Then, define join of labels as AND operation on the bits as well as the roles. 
- We need to define the join of roles, and since we will be encoding labels back 
  into permission, we will have some compromises we need to do. 
- Introduce the join of roles for user and groups.
- We introduce two principals: manyusers and manygroups to denote joins with 
  different users and groups, respectivelly. 
- No one in the system, except the administrator have the authority for
  manygroups and manyusers -- so the data with this label is likely to not 
  be useful for the users of the system without the approval of the
  administrator. There could be other ways to encode many users into a user 
  id but we avoid this route to keep it simple. 
- In any case, such labels will ensure to provide confidentiality and integrity 
  for users working on the same groups, without affecting files from users in 
  other groups. Give an example. 
- We also propose to relax the definition of join to avoid label creep by introducing 
  that if a file has the read permission for the role others, then it is 
  considered labels with the bottom element. 


