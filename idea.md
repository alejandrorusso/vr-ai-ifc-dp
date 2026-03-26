# Idea for the VR proposal 


SECURING AI DECISION PIPELINES WITH INFORMATION FLOW CONTROL AND DIFFERENTIAL
PRIVACY


Main motivation: 

- Large Language Models (LLMs) are rapidly integrated into high-stakes
  decision-making workflows across many sectors with AI agents. 

- Today’s tools that give LLMs capabilities to interact with the real world via
  MCP Servers that are overprivileged and highly vulnerable to prompt injection
  and data leakage. 

- This proposal introduces a secure, trustworthy AI architecture based on (i)
  Information Flow Control (IFC), a technology from the military domain that
  enforces end-to-end confidentiality and integrity, and (ii) Differential
  Privacy (DP) for quantifiable privacy guarantees in data releases. 

- We adapt IFC and DP to modern AI systems, enabling LLMs to safely interact
  with data and MCP tools to create AI agents which, by construction, it
  prevents unauthorized information flows and malicious manipulation of AI
  agents.  


Idea of research: 

- Weaker guarantees: control flow integrity 
    - Arrows and control flow for planning --- re-encode patterns there as a DSL 

- Stronger guarantees for confinement: IFC
    - Retrofitting permissions and labels (a bit theoretical) 
    - Privileges and reasoning about it... what Julius is doing. 
    - eBPF, is it possible? loops (more practical)

- Stronger guarantees for data release: DP 
    - Generation of queries: use of high-level encoding of invariants in queries (a
      bit what DPella does) for generating them. 
    - Systematization of DP into prompts (a bit of prompt engineering)
    - Cache via normalization by evaluation 
