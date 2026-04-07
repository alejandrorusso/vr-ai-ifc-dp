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
  Privacy (DP) for quantifiable privacy guarantees for data releases. 

- We adapt IFC and DP to modern AI systems, enabling LLMs to safely interact
  with data and MCP tools to create AI agents which, by construction, it
  provides confinement, mitigates malicious manipulation by prompt injections,
  and safely consume data insights from sensitive data. 

These are the technical challenges the proposal will address: 

# Goal 1: ensuring control flow integrity via a strongly-typed domain specific language (DSL)
    - Challenge: (i) design of an AI planning DSL that is flexible enough and
      encodes several of the patterns found [Design Patterns for Securing LLM
      Agents against Prompt Injections](./biblio/ai security/patterns.pdf),
      specially those that depend on data processed by LLMs -- where prompt
      injection attacks can occur; and (ii) provide enough typing discipline in
      the DSL that type-errors can help the LLM to synthezise correct plans --
      thus reducing hallucinations.
    - Proposal: using [Arrows](./biblio/arrows/arrows.pdf) to encode several of
      the patterns described in the paper [Design Patterns for Securing LLM
      Agents against Prompt Injections](./biblio/ai security/patterns.pdf).  
    - Technique: I need to think about this but it and perhaps I can get
      inspired by some of my [previous work on IFC on
      arrows](./biblio/arrows/arrows_ifc.pdf)

# Goal 2: mitigating prompt injection attacks while providing confinement 
    - Challenge: provide a harness for AI agents that mitigates prompt injection
      attacks by construction but also that preserves that confidentiality and
      integrity of the data being processed by the LLM. 
    - Proposal: A floating label information-flow control system for AI agents. 
    - Technique: 
        - Repurposing several of my work on [LIO](./biblio/lio/lio-jfp.pdf) -- a
          language-based approach for OS Mandatory Access control principles
          applied to [concurrent systems](./biblio/lio/lio-concurrent.pdf), and
          the [web](./biblio/practical lio-principles/cowl.pdf) -- so that we
          obtain a flexible IFC control for AI agents that reduces label creep.  
        - We show that we can encode [FIDES](./biblio/ai security/fides.pdf) in
          term of LIO for AI agents. 
        - We will use file system permissions as IFC labels to be practical
          while theoretical sound. We will encode UNIX file-like permissions
            into [DC-labels](./biblio/lio/dc-labels.pdf). 
        - Implementing end-to-end IFC tracking for agents at the OS-level by
          leveraging [eBPF](./biblio/ebpf/Engineering_Everything_with_eBPF.pdf)
          -- thus showing that eBPF has evolved enough to support such a design. 

# Goal 3: privacy boundary for AI agents accessing sensitive data 
    - Challenge: often, Agents want to access data to learn about trends of 
    populations and not specific individuals. If a traditional IFC system, 
    the LLM will get tainted quickly and hit the label creep problem. In this 
    light, we want a mechanism that AI agents can mine data insights without 
    getting tainted. 
    - Proposal: we will connect LLM agents with Differential Privacy systems
      (something that has not been explored before). As most tools provide
      custom programming languages (because they need to have a strict control
      about what is learned form the data), LLM needs to generate queries in
      domain-specific languages that have not been trained before. 
    - Technique: we propose that AI agents only extract differentially private
      results from sensitive data. In that manner, AI agents only see
      privacy-protected insigts. 
        - Propose a domain-specific language that encodes at the type-level
          several invariants in queries related to enforce the right injection
          of calibrated noise by the DP mechansim. This is inspired by the PI's
          work on [Sensitivity by Parametricity](./biblio/dp/sensitivity_parametricity.pdf) and 
          [DPella](./biblio/dp/sp20.pdf).
        - Systematization of DP workflows into prompts (a bit of prompt
          engineering), e.g., analyzing the schema of the dataset, then propose
          typical data analyses (maybe guided by synthetized examples),
          exploration of privacy-accuracy trade-offs, and visualization. This
          has not been tried before to the best of my knowledge.


Context: 
- Besides filesystem, Agents also need to connect to databases to fetch 
  e.g., finantial, HR, or intellectual property information.
- In this scenario, in traditional IFC system, the LLM will get tainted quickly 
  when getting access to the raw tables for analysis -- again label creep
  problem. 
- In this light, we want a mechanism that AI agents can mine data insights without 
  getting tainted. 
- We propose then that AI agents craft Differential Privacy queries, so they
  received "anonymized" insights so tainting can be avoided. 
  
Problem:
- There are challenges, however, most DP tools work on their own DSL (e.g.,
  OpenDP, DiffPrivLib, DPella).
- Since DP entails expending privacy budget (introduce the notion) each time 
  that you run a query, then it is very important that (i) the query is correct 
  and runs until completion, and (ii) you know the accuracy of the results up
  front.

Approach: 
- We propose to design a query language that encode invariants of the queries 
  at the type-level. 
- In that way, the LLM needs to "fight" the type-system, getting feedback
  continously to synthetize the right query required by the user. 
- The novelty here is to push data schemas at the type-level (here cite 
  some haskell papers on databases and types) but that 
  are generic enough to encode whatever data schema that comes at runtime -- 
  for that we plan to use generic programming techniques (cite Sum-of-products
    paper).
- Once that is Ok, then accuracy analysis can be performed and report back. 






