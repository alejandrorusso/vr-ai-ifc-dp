# For the rest of the section

Paragraph about overall goal and architecture: 
- We want an IFC enforcement that does not require modifying the agent or tools
  code and be applicable to current ai agent coding systems. 
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





