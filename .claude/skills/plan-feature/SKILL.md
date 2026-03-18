---
name: plan-feature
description: Orchestrate the full planning workflow for a feature. Runs codebase research, impact analysis, and produces a file-by-file implementation plan. Use when starting work on a new feature, especially multi-layer features that span backend and frontend.
argument-hint: [Path to requirements file (e.g., docs/requirements/ABC-123.xml)]
disable-model-invocation: true
---

# Plan Feature

Orchestrate the full planning workflow for "$ARGUMENTS".

You coordinate five phases — context gathering, scoping, codebase research, impact analysis, and planning — then report the results. Complete all phases in order.

## Phase 0: Gather context

Run these commands in parallel to establish context:

- `git branch --show-current` — extract the ticket identifier from the branch name
- `ls docs/requirements/` — check available requirements files
- `ls docs/plans/` — check for existing plans (avoid duplicating work)

## Phase 1: Read requirements and identify scope

1. **Read the requirements.** If $ARGUMENTS is a file path (e.g. `docs/requirements/ABC-123.xml`), read it. If it's a ticket number, look for a matching file in `docs/requirements/`. If it's a description, use it directly.

2. **Read CLAUDE.md** — specifically the **Reuse Before Reimplementing** section, the **Custom Magento Modules** table, and the **Architecture** section. Identify:

   - Which reference features are the closest analogues
   - Which existing modules might be extended vs. a new module needed
   - Which shared files will likely need modification (provider singleton, types file, GQL index)

3. **Determine the technical needs** of the feature: does it need a GraphQL mutation? Transactional emails? Admin config? A frontend form? A widget? Map each need to the reference feature from the Reuse table.

## Phase 2: Research via codebase-qa agents

Based on the analogues and technical needs identified in Phase 1, use the **Agent tool** to launch **2–5 `codebase-qa` agents in parallel**. Each agent call must use `subagent_type: "codebase-qa"`.

**Formulate targeted questions.** Each question should target a specific cross-layer flow or integration point. Examples (adapt to the actual feature):

- "How does the [reference module] resolver receive form data and pass it to the model? Show the full flow from schema.graphqls to the model method."
- "What data attributes does the [reference widget] read from its mount element, and where does the PHTML template set them?"
- "How does [reference module] handle email sending — what's the flow from resolver through to TransportBuilder, including branch routing and BCC?"
- "What admin config fields does [reference module] define in system.xml and how are they read in the model via ScopeConfigInterface?"
- "How does the [reference form] component structure its steps, and how does cross-step data sharing work?"

**How to invoke:** Use the `Agent` tool (NOT "Subagent" — the tool is called `Agent`) like this for each research question:

```
Agent tool call:
  description: "Research [topic]"
  subagent_type: "codebase-qa"
  prompt: "[your targeted question]"
```

**Guidelines:**

- Launch at least 2 Agent calls, up to 5 depending on feature complexity
- Each question targets ONE specific flow — not "tell me everything about module X"
- Launch ALL Agent calls in a single message for parallel execution
- Wait for all to complete before proceeding

**Record results.** For each agent, note the question asked and a one-line summary of the key finding. You'll pass these to the planner.

## Phase 3: Impact analysis via impact-analyser agents

After research completes, identify which **existing shared files** the feature will need to modify. Typical candidates:

- The GraphQL provider singleton (adding new methods)
- The shared TypeScript types file (adding new types)
- The GQL barrel index (adding new exports)
- Existing admin config sections (adding new groups/fields)
- Shared PHP interfaces in `Api/`

**If shared files will be modified**, use the **Agent tool** to launch **1–3 `impact-analyser` agents in parallel**, one per high-risk shared file:

```
Agent tool call:
  description: "Impact analysis [target]"
  subagent_type: "impact-analyser"
  prompt: "Analyse the impact of [modification] to [file]"
```

Example prompts:

- "Analyse the impact of adding new methods to [provider singleton file]"
- "Analyse the impact of modifying [shared types file] to add [new types]"
- "Analyse the impact of adding a new group to [admin config section]"

**If the feature only creates new files** with no modifications to existing shared code, skip this phase. Note: "Impact analysis: skipped (all new files, no shared modifications)."

**Record results.** For each agent, note the target analysed and a one-line summary of findings.

## Phase 4: Delegate to `feature-planner`

Spawn the `feature-planner` agent via the Agent tool. Do not write the plan yourself — the `feature-planner` has specialized skills (react-patterns, magento-module, email-patterns, etc.) that produce a higher-quality plan.

Include in the prompt:

1. The original requirements (full text or summary)
2. A **Research Findings** section with all codebase-qa results
3. An **Impact Analysis** section with all impact-analyser results (or "skipped" note)
4. Any constraints or scope notes you identified in Phase 1

**Invoke like this:**

```
Agent tool call:
  description: "Plan feature implementation"
  subagent_type: "feature-planner"
  prompt: "[structured prompt as shown below]"
```

Structure the prompt like this:

```
Plan the implementation of the following feature.

## Requirements
[paste or summarise the requirements]

## Research Findings
The following codebase research was conducted by codebase-qa agents:

### Research 1: [question]
[paste the sub-agent's response]

### Research 2: [question]
[paste the sub-agent's response]

[...repeat for each research sub-agent]

## Impact Analysis
The following impact analysis was conducted by impact-analyser agents:

### Impact 1: [target]
[paste the sub-agent's response]

[...repeat for each impact sub-agent, or note "Skipped — all new files"]

## Constraints
[any delivery constraints, scope notes, or decisions from Phase 1]
```

## Phase 5: Report

After the `feature-planner` agent completes, report:

1. The saved plan file path
2. A summary of agent activity:

```
## Agent Activity Report

| # | Agent Type | Question / Target | Key Finding |
|---|---|---|---|
| 1 | codebase-qa | [question] | [one-line summary] |
| 2 | codebase-qa | [question] | [one-line summary] |
| 3 | impact-analyser | [target] | [one-line summary] |
| 4 | feature-planner | [one-line prompt summary] | [one-line summary] |

**Totals:** X codebase-qa agents, Y impact-analyser agents, Z total.
```

3. The number of open questions in the plan
4. A reminder: "Review the plan at [path]. Verify you can explain the feature's data flow end-to-end before running the feature-implementer."
