# Prepare CLAUDE CODE with Python-Specific Context

## Task
Read the project’s `CLAUDE.md`. Ensure all Python rules below are present. If partially present, reorganize and edit `CLAUDE.md` so all rules are included exactly and unambiguously.

## Python Rules

### Environment
1. Manage the dev environment with `flake.nix` only.
2. Assume `nix develop` is active.
3. Do not use `pip`, `uv`, or `poetry`.
4. Run programs as modules: `python -m package.module`.

### Library Preferences
1. Use builtin **unittest**.
   - Discover all tests: `python -m unittest discover`
   - Run verbose/specific: `python -m unittest -v path/to/test_file.py`
2. Use **pydantic v2** for schemas and domain models.
3. Use **PyTorch** and **JAX** for ML models.
4. Use **loguru** for logging.
5. Use **click** for CLI/arg parsing.
6. Prefer **pathlib** over `os.path`.
7. Use explicit `StrEnum` / `IntEnum` for enums.

### Code Style
1. **Use absolute imports**; do not use relative imports (e.g., avoid `from .x import y`).
2. Prefer specific imports (e.g., `from pydantic import BaseModel`).
3. **Use type hints everywhere**:
   - Annotate all function parameters and return types.
   - Use builtin generics (`list`, `dict`, `tuple`) instead of `typing.List`, etc.
   - For optionals, use `MyType | None` instead of `Optional[MyType]`.

### Documentation
1. **Write docstrings for all public modules, functions, classes, methods**, and public-facing APIs. PEP 8 and PEP 257 recommend docstrings for all public elements.
2. In docstrings:
   - **Do not include types in the `Args:` section**, type hints in signatures cover that.
