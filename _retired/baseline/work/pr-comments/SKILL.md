---
name: pr-comments
description: Publish the findings from a completed pull request review as inline Azure DevOps pull request comments. Use after a PR review has identified critical issues, important issues, advisory suggestions, strengths, or other review observations.
---

# Publish Azure DevOps PR review comments

Use this skill after a pull request review has been completed.

The purpose of this skill is to convert the review findings into useful,
appropriately placed Azure DevOps pull request comments.

The publishing skill may transform, locate and format review findings, but must not introduce new review findings.

## Inputs

Expect the current context to contain:

- the Azure DevOps pull request being reviewed
- the review findings
- the changed files / diff
- sufficient repository information to locate the relevant code

Review findings may include:

- Critical issues
- Important issues
- Advisory suggestions
- Strengths / positive observations
- General observations

## Workflow

1. Read all findings from the completed PR review.

2. For each finding:
   - identify the affected file
   - identify the most relevant changed line or code range
   - determine whether the finding should be an inline comment or a
     general PR comment

3. Prefer inline comments where the finding relates to identifiable code.

4. Publish each actionable finding as a separate Azure DevOps PR comment.

5. Prefix comments with their classification:
   - `[Critical]`
   - `[Important]`
   - `[Advisory]` 
   - `[Strength]`

6. Keep comments concise and actionable.

7. Explain why something matters rather than merely stating that it is wrong.

8. Do not invent findings that were not present in the review.

9. Do not duplicate substantially identical findings.

10. If a finding cannot reliably be mapped to a line in the PR diff,
    publish it as a general PR comment instead.

11. Publish a general comment to highlight the positives and strengths of the work.

12. Publish a general comment summarising the work and the review that has happened. Discuss the result of the review, which may be "accept", "accept with suggestions", "needs work - await author" or "rejected".

13. Only create inline comments for issues classified as [Critical] or [important].  

14. Publish all [Advisory] issues together in a single general comment. Generally do the same for [Strength]s, but occasionally praise particularly well-written code with the odd inline comment. These occasional [Strength] inline comments should be immediately "resolved".

15. End each comment with "** Written by Claude via ado-mcp **"

## Comment style

Prefer:

> [Important] This cancellation token is not propagated into the database
> call, so cancellation of the HTTP request will not stop the query.
> Pass `cancellationToken` through to `ToListAsync`.

Avoid:

> This is wrong. Fix cancellation.

For advisory comments, make clear that the suggestion is optional:

> [Advisory] Consider extracting this mapping into a helper. This isn't
> required for correctness, but it may make the handler easier to scan.

Positive feedback may also be inline where appropriate:

> [Strength] Nice use of the existing validation abstraction here. This
> keeps the new behaviour consistent with the surrounding code.

## Rules

- Never modify the PR as part of this skill.
- Never resolve existing comment threads.
- Never approve or reject the PR.
- Never publish a comment without being confident that it applies to the
  referenced code.
- Avoid commenting on unchanged lines unless Azure DevOps requires the
  surrounding context to anchor the thread.

See `references/severity-guidance.md` for classification rules.

See `references/azure-devops-pr-comments.md` for Azure DevOps-specific
thread and line-position conventions.