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


These are the technical challenges the proposal will address: 

# Goal 1: ensuring control flow integrity via a strongly-typed domain specific language (DSL)
    - Challenge: (i) design of an AI planning DSL that is flexible enough and encodes several of 
      the patterns found "Design Patterns for Securing LLM Agents against Prompt Injections", 
      specially those that depend on data processed by LLMs -- where prompt
      injection attacks can occur; and (ii) provide enough typing discipline in
      the DSL that type-errors can help the LLM to synthezise correct plans --
      thus reducing hallucinations.
    - Novelty: using Arrows to encode several of the patterns described in the
      paper "Design Patterns for Securing LLM Agents against Prompt Injections"
      (see papers)
    - How to do it: I need to think about this

# Goal 2: mitigating prompt injection attacks while providing confinement 
    - Challenge: provide a harness for AI agents that mitigates prompt injection
      attacks by construction but also that preserves that confidentiality and
      integrity of the data being processed by the LLM. 
    - Novelty: A floating label information-flow control system for AI agents. 
    - How to do it: 
        - Repurposing several of my work on LIO -- a language-based approach for 
          OS Mandatory Access control principles (see papers) -- so that we
          obtain a flexible IFC control for AI agents (reducing label creep).  
        - Based on FIDES (see Microsoft paper), we will encode it in the shape
          of LIO principles.
        - Using file system permissions as IFC labels to be practical while 
        theoretical sound. We will encode UNIX file-like permissions into
        DC-labels (see papers). 
        - Implementing end-to-end IFC tracking for agents at the OS-level by 
        leveraging eBPF -- thus showing that eBPF has evolved enough to support 
        such a design. 

# Goal 3: privacy boundary for AI agents accessing sensitive data 
    - Challenge: often, Agents want to access data to learn about trends of 
    populations and not specific individuals. If a traditional IFC system, 
    the LLM will get tainted quickly and hit the label creep problem. In this 
    light, we want a mechanism that AI agents can mine data insights without 
    getting tainted. 
    - Novelty: we will connect LLM agents with DP systems (something that has 
    not been explored before). As most tools provide custom programming
    languages (because they need to have a strict control about what is learned
    form the data), LLM needs to generate queries in domain-specific languages
    that have not been trained before. 


    - Generation of queries: use of high-level encoding of invariants in queries (a
      bit what DPella does) for generating them. 
    - Systematization of DP into prompts (a bit of prompt engineering)
    - Cache via normalization by evaluation 
