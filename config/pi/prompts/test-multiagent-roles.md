---
description: Smoke-test custom pi-multiagent roles in one read-only graph
argument-hint: "[scope]"
---
/skill:pi-multiagent
Smoke-test the custom user pi-multiagent roles${1:+ for $1}.

Requirements:
- Use `agent_team` only.
- First call `catalog` with `library.sources:["user"]` and confirm these refs exist: `user:mini-scout`, `user:mini-reviewer`, `user:mini-synthesizer`, `user:deep-planner`.
- Then start one inline read-only graph with `graph.library.sources:["user"]` and `graph.authority.allowFilesystemRead:true`.
- No bash, no edits, no writes.
- Use the current working directory only.

Graph shape:
- `scout` with `user:mini-scout`: inspect the relevant repo surface${1:+ for $1}; return paths, facts, unknowns.
- `planner` with `user:deep-planner`: depends on `scout`; propose the smallest sane next plan and stop condition.
- `review` with `user:mini-reviewer`: depends on `scout`; do a lightweight risk review of the same surface.
- `synth` with `user:mini-synthesizer`: depends on `scout`, `planner`, and `review`; merge the evidence.

After `start`:
- wait with `run_status`
- fetch `step_result` with `preview:true` for `scout`, `planner`, `review`, and `synth`
- finish with a compact summary that includes the effective model and thinking lane for each step
