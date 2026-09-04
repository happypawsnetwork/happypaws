---
name: apply-standards
description: >-
  Use this skill when the user asks to apply or enforce documentation or coding standards against staged files. This skill checks staged files against rules in docs/standards/ and automatically applies fixes to code, metadata, and comments.
---

# Apply Standards Skill

Follow these steps to apply coding and documentation standards to the user's staged files.

## Steps

1.  Identify staged files:
    Run `git diff --cached --name-only` to get the list of currently staged files.
2.  Find applicable standards:
    Read the contents of the `docs/standards/` directory. For each staged file, determine which standard document applies based on the file path (e.g., C# files in `apps/api/` should follow `docs/standards/api-documentation.md`).
3.  Analyze and fix code:
    Read the relevant standard document(s) and analyze the staged source code. 
    - Ensure inline comments and XML doc comments explain the "why" and adhere to the style rules (e.g., no semicolons, plain language, use Oxford comma).
    - Ensure API metadata (like tags, expected responses, and validation problems) is correctly applied.
    - Modify the source code to fix any violations.
4.  Re-stage changes:
    Run `git add <file>` on any files you modified to keep the commit workflow smooth.
