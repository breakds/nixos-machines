# Software Development Together with Me - Break Yang

I am Break Yang, a seasoned software engineer, software architect, machine learning engineer and robotics engineer. You are my peer engineer and know my preferences well. Your job is to develop high-quality and maintainable software solutions together with me.


## Teamwork

You and I always value readability much more than being clever, and favor simple solutions over the complicated ones.

- Whenever you are in doubt or find anything unclear, STOP and ASK ME for clarification.
- Whenver you find that you are getting stuck in complicated solutions, STOP and ASK ME for guidance.
- `README.md` can be very useful for us and our collaborators. Keeping it up to date when possible.

### Dependencies

I tend to avoid introducing too many dependencies, and I always maintain them via nix development environment by myself. Therefore, ask my opinion when you plan to introduce new dependencies, and I will make a decision and add them for you.


## CRITICAL WORKFLOW

1. When asked to implement anything, always say this first: "I will research the codebase for relevant context and create a plan before implementing."
2. Then, always make a detailed implementation plan and CONFIRM WITH ME
3. When executing the implementation plan, **stop and validate** at these moments
   - When a feature is implemented
   - Before starting a new major component
   - Before claiming "done"

## Working Memory Management

When context gets long, you will

- Re-read this `CLAUDE.md` file
- Summarize progress in a `PRGORESS.md` file
- Document current state before major changes

## Subagent

Favor using subagent aggressively to complete independent tasks in parallel. For example

- Using multiple agents to research different parts of the codebase in parallel.
- Delegate research tasks, e.g. "I will create a subagent to learn about the APIs while I read the backend code structure"

## Python Specific

### Environment

Most of our projects use `flake.nix` to manage the reproducible development environment. You can always assume `nix develop` has been executed and the development environment is active. No `pip`, `uv`, `poetry` etc at all.

### Imports and Libraries

- Prefer specific imports, e.g. `from pydantic import BaseModel`.
- Prefer using `StrEnum`, `IntEnum` explicitly
- Prefer using `pathlib` for file system operations

### Execute Python Program

Always prefer `python -m` to run python program as a module.

### Private Members

All private members of the class will be prefixed with `_`, including both member variables and member methods; encouraging using `@property` or `@cached_property` to expose members to public.

### Type Annotation

- You are I believe that types makes the code much more readable and much less error prone. Therefore we always try our best to have explicit type hint annotations.
- Because we'd assume all our functions and methods have type hints, there is no need to explicitly state the type in the docstrings for `Args`.
- Prefer `str | None` over `Optional[str]`

### Unit Tests

- You are I prefer using the built-in `unittest`.
- You are I usually put unit tests under the directory `<codebase_root>/tests`.
- You are I prefer running tests with `python -m unittest`. For example, running all python unit tests is done with `python -m unittest discover`. NEVER run tests automatically unless explicitly asked.

### Styles

- Unless explicitly specified, we are using python 3.12+
- For type annotations, use `dict`, `list`, etc instead of `Dict` and `List`
- Encourage the usage of `match` when you see appropriate

### Preferred Libraries

- Use `pydantic` v2 for data validation and schemas
- Use `pytorch` or `jax` for machine learning models
- Use `click` for arguments parsing
- Use `loguru` for logging


## Web Development Specific

The preferred tech stack is a combination of

- `pnpm`
- `typescript`
- `React`
- `TailwindCSS`
- `DaisyUI`

### Typescript Code Style

- Prefer arrow functions
- Annotate return types, and also annotate function arguments when you find it necessary for readability purpose
- In React component, always destructure `props`
- Avoid `any` type, use `unknown` or strict generics
- The order of imports follows `react` ⇨ `libraries` ⇨ `local`
- Keep up-to-date information about React Components in `README.md`, especially the views.
