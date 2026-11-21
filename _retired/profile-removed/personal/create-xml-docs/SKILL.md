---
name: create-xml-docs
description: Creates XML documentation comments for all public members of a given code file. Use this skill when the user asks to document a file, add XML docs, generate XML comments, or document public APIs, classes, methods, or interfaces. Trigger when the user provides a filename and wants documentation added to it.
---

# Create XML Documentation

Generates XML documentation comments for all public-facing members of a code file. Operates only on public items — skips private, protected, and internal members entirely.

## What to Document

For each public member, generate the appropriate XML doc tags:

- **Classes / Interfaces / Structs / Enums** — `<summary>`
- **Methods / Constructors** — `<summary>`, `<param>` for each parameter, `<returns>` (omit `<returns>` for void/constructors), `<exception>` for any exceptions the method is documented or known to throw
- **Properties** — `<summary>`, `<value>` if the property has a non-obvious value range or meaning
- **Fields** (public only) — `<summary>`
- **Events** — `<summary>`
- **Generic type parameters** — `<typeparam>` for each

## Documentation Style Rules

- Write in third person present tense ("Gets the value", "Initialises a new instance of...")
- Be concise but complete — one sentence for `<summary>` is usually enough; add `<remarks>` only when genuinely needed for clarity
- For `<param>`, describe what the argument represents, not its type (the type is already in the signature)
- For `<returns>`, describe what the return value represents, not just its type
- For `<exception>`, include the exception type as the `cref` attribute and describe the condition that causes it
- Do not document obvious things like `/// <summary>Gets or sets the Name.</summary>` for a property called `Name` on a `Person` class — add real meaning
- Use `<see cref="..."/>` to cross-reference other types or members where relevant

## Process

1. Read the file provided by the user
2. Identify the language (C#, Java, TypeScript, etc.) and use the correct comment syntax:
   - C# / Java → `/// <tag>`  
   - TypeScript / JavaScript → `/** <tag> */` (JSDoc-compatible XML)
   - VB.NET → `''' <tag>`
3. Identify all public members — skip anything marked private, protected, internal, or with a visibility modifier that restricts access
4. For each public member, write the appropriate XML comment block directly above it
5. Output the **entire file** with documentation added in place — do not summarise or truncate

## Output

Return the full modified file contents. If the file is large, output it in a code block with the correct language identifier. Do not output only the changed sections.

## Example (C#)

Input:
```csharp
public class OrderService
{
    public Order GetById(int id) { ... }
    private void validate(Order order) { ... }
}
```

Output:
```csharp
/// <summary>
/// Provides operations for managing orders.
/// </summary>
public class OrderService
{
    /// <summary>
    /// Retrieves an order by its unique identifier.
    /// </summary>
    /// <param name="id">The unique identifier of the order to retrieve.</param>
    /// <returns>The <see cref="Order"/> with the specified identifier.</returns>
    /// <exception cref="KeyNotFoundException">Thrown when no order with the given <paramref name="id"/> exists.</exception>
    public Order GetById(int id) { ... }

    private void validate(Order order) { ... }
}
```
Note: `validate` is private — no documentation added.