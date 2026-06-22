---
description: Heavy pi-multiagent test that builds a small static webpage with custom user roles
argument-hint: "[target-dir]"
---
/skill:pi-multiagent
Run a heavier end-to-end multiagent test by building a static webpage in ${1:-multiagent-webpage-test}.

Requirements:
- Use `agent_team` only.
- First call `catalog` with `library.sources:["user"]` and confirm these refs exist: `user:mini-scout`, `user:deep-planner`, `user:deep-worker`, `user:mini-reviewer`, `user:mini-synthesizer`.
- Then start one inline graph with `graph.library.sources:["user"]`.
- Set `graph.authority.allowFilesystemRead:true` and `graph.authority.allowMutationTools:true`.
- Do not grant bash.
- Use the current working directory only.
- Own only `${1:-multiagent-webpage-test}` under the cwd. If that directory already contains unrelated work, stop and report instead of editing.

Product goal:
- Build a small self-contained static landing page for a fictional AI product.
- Keep it dependency-free.
- Prefer 1 to 3 files max (`index.html`, optional `styles.css`, optional `script.js`).
- Include semantic HTML, responsive layout, clear CTA, accessible contrast, and at least one tiny interactive touch if it helps.

Graph shape:
- `scout` with `user:mini-scout`: inspect cwd, confirm whether `${1:-multiagent-webpage-test}` is safe to own, and identify any constraints from nearby files.
- `planner` with `user:deep-planner`: depends on `scout`; propose the smallest sane implementation plan, file list, and stop condition.
- `build` with `user:deep-worker`: depends on `scout` and `planner`; create the webpage only inside `${1:-multiagent-webpage-test}`.
- `review` with `user:mini-reviewer`: depends on `build`; review the created webpage for obvious issues, missing basics, and unnecessary complexity.
- `synth` with `user:mini-synthesizer`: depends on `planner`, `build`, and `review`; merge the evidence into one final handoff.

After `start`:
- wait with `run_status`
- fetch `step_result` with `preview:true` for `scout`, `planner`, `build`, `review`, and `synth`
- finish with a compact summary that includes the effective model and thinking lane for each step, files created, and any review findings
