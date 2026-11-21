# Azure DevOps PR Comment Publishing

Prefer comments attached to the changed line that caused the observation.

For each comment determine:

- repository
- pull request ID
- file path
- line number
- whether the line belongs to the left/original or right/modified side
- comment body

Prefer the modified/right-hand side of the diff when commenting on newly
introduced or changed code.

If no reliable line mapping exists, create a general pull request thread.

Do not guess line positions.