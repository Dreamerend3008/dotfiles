---
description: Write a clean commit message from the current git diff
argument-hint: "[style]"
---
Inspect the current git changes and write a commit message.

Requirements:
- Summarize the real user-facing or repo-facing change.
- Prefer a concise imperative subject line.
- Include a short body only if it adds value.
- Mention linked Home Manager/Pi wiring changes when relevant.
- If the diff mixes unrelated changes, point that out before suggesting a message.

Style preference: ${1:-standard git commit style}
