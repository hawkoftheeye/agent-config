---
name: pr-description
description: use this skill when being asked to generate descriptions to accompany a new PR in ADO.
---

# PR Description Text

Generate a body of text that the user can use to accompany a new PR in Azure DevOps. The description should accurately represent the current diff.

The description should be encoded in Markdown, to ensure code items are appropriately formatted.

Write the output to a file at docs/12345-pr.md, where the number matches the ADO ticket being worked on. If this is unknown, create an appropriate title from the context of the work.

The description must be under 4,000 characters in total including all encoding. However, this is a top limit. Aim to keep the description brief, taking care to cover all the necessary points, but without extra filler.

Use the following template as a starting point (although feel free to deviate if the situation demands):

## Overview

*A 2–4 sentence summary describing:*
- *the problem being solved*
- *what changed*
- *current status (complete / partial / exploratory)*

## What Was Done

*Bullet points describing meaningful units of work.*
*Focus on behaviour and architecture rather than individual files or commits.*

## Decisions & Rationale

*Document non-obvious technical decisions, trade-offs, assumptions, rejected alternatives, and deliberate deferrals.*

## Validation

*Briefly describe how the work was verified.*
*Mention tests added, existing tests run, manual validation, or if validation is still outstanding.*

## Risks & Watch Points

*Anything unfinished, fragile, untested, performance-sensitive, or worth monitoring.*

## Open Questions

*Optional.*
*Record any uncertainties or design questions that emerged during the session.*

## Next Steps

*Optional.*
*If someone resumed this work tomorrow, what should they do first?*