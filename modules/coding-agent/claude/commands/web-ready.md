# Prepare CLAUDE CODE with Web Development Context

## Task

Read the project’s `CLAUDE.md`. Ensure all web development rules below are present. If some are missing or partially present, reorganize and update `CLAUDE.md` so every rule is included clearly and unambiguously.

## Web Development Rules

### Language & Syntax

1. Use **TypeScript** only (no plain JavaScript).
2. Omit unnecessary semicolons—that is, do not add semicolons at statement ends unless required.
3. Prefer **arrow functions** (`const f = () => ...`) for concise, inline code and callbacks. Use **function declarations** for named or top-level functions where `this` or hoisting matters.

### Typing & Imports

1. Always use **explicit types**, especially for function parameters and return values. Annotate returns and arguments when it improves readability.
2. Avoid `any`. Use `unknown` or properly constrained generics instead—`unknown` forces safe type narrowing.
3. Organize imports in this order:

   * `react`
   * third-party libraries
   * local modules
4. Support **absolute imports** in `.ts`/`.tsx` files, e.g.:

   ```ts
   import '@/components/MarkdownPreviewPanel'
   ```

   resolves to `src/components/MarkdownPreviewPanel.tsx`.

### React & Components

- In React components, always **destructure `props`** directly in function parameters.
- Keep `README.md` updated with essential information about React components—especially view or UI-related ones.

### Documentation

- Document important functions, classes, and React components with inline docstrings or comments for clarity and maintainability.
