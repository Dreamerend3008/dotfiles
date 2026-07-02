---
name: obsidian-transcript-note
description: Create or update Markdown notes in ~/Notes from voice transcripts for Obsidian/Nvim. Use when a transcript should become a note, summary, study note, inbox capture, or transcript-backed draft without inventing facts.
---

# Obsidian Transcript Note

Use this skill when turning a transcript into a note in `/home/harry/Notes`.

## Goals

- Make cheap models safe and boring.
- Match the user's existing note style.
- Never invent facts that are not in the transcript.
- Prefer a usable draft in the right format over a clever summary.

## Required workflow

1. Use `ctx_execute_file` on the transcript file first.
   - Extract only concrete facts, tasks, headings, names, dates, and obvious structure.
   - Keep uncertain or low-confidence transcript fragments out of the final note.
2. Inspect a few existing notes in `~/Notes` that are closest to the topic before writing.
   - Match their formatting, frontmatter shape, heading style, and folder choice when clear.
3. Write plain Markdown only.
   - Keep the existing frontmatter shape when creating a note:

```yaml
---
id: note_id
aliases:
  - note_id
tags: []
---
```

4. Prefer simple structure:
   - title/headings
   - short paragraphs
   - bullet lists
   - checklists for action items only when the transcript implies tasks
5. If the destination is ambiguous, write a safe draft instead of guessing.
   - Prefer `~/Notes/transcripts/` or another obvious inbox-like location if one already exists.
   - If no clear destination exists, create `~/Notes/transcripts/` and place the draft there.
6. Final answer must be short and include the resulting file path.

## Hard rules

- Do **not** invent facts, citations, dates, URLs, or conclusions.
- Do **not** silently merge transcript content into an unrelated existing note.
- Do **not** over-format. No tables unless the transcript naturally demands one.
- Do **not** use JSON, HTML, or exotic Markdown extensions.
- Do **not** read large notes fully if a few targeted reads establish the style.

## Content rules

### What to keep
- clear facts stated in the transcript
- clear tasks or next actions
- obvious sections from the speaker's structure
- brief clarifications like `Unclear in transcript:` when needed

### What to drop
- filler words
- repeated phrases
- transcript noise
- guesses about intent
- weakly-heard claims

## Naming and placement

- Reuse the folder pattern already present in `~/Notes` when obvious.
- Derive `id` from the filename stem in lowercase snake_case when creating a new note.
- Keep `aliases` aligned with the same stem unless existing local conventions show otherwise.
- If the transcript is general capture with no clear home, use a transcript/inbox-style folder rather than guessing a permanent taxonomy.

## Minimum self-check before finishing

Confirm all of these:

- file is inside `~/Notes`
- Markdown is valid and readable
- frontmatter exists for new notes and matches the existing simple shape
- every factual claim comes from the transcript
- final answer includes the saved path

## Preferred output shape

Use the smallest note that is useful. Example:

```markdown
---
id: example_note
aliases:
  - example_note
tags: []
---

# Example note

## Summary
- fact from transcript
- another fact from transcript

## Action items
- [ ] only if the speaker clearly requested a follow-up

## Open questions
- unclear term from transcript
```
