# Repository Guidelines

## Project Structure & Module Organization

Cosmic Tree Fighters is a Defold game using Lua 5.1. `game.project` defines dependencies, rendering, physics, and the bootstrap collection, `main/main.collection`.

- `main/scripts/`: gameplay scripts; `modules/` contains shared gameplay logic, `common/` utilities, `skills/` abilities, and `units/` enemy behavior.
- `main/gui/`: screens, GUI scripts, and collection proxies.
- `main/prefabs/`: reusable player, enemy, building, buff, and spell objects.
- `main/tilemaps/`, `main/atlases/`, `main/tilesources/`: level and sprite resources.
- `assets/`: artwork, fonts, and sounds; `input/game.input_binding` defines controls.
- `.vscode/`: development tasks, debugger settings, and formatting configuration.

## Build, Test, and Development Commands

Install the recommended VS Code extensions, including Defold Kit and Local Lua Debugger. Set `defoldKit.general.editorPath` to your actual Defold installation; the checked-in path is machine-specific.

Use **Terminal → Run Task** for these tasks:

- **Resolve**: fetch dependencies after changing `game.project` dependencies.
- **Build** (`Ctrl/Cmd+Shift+B`): compile the game.
- **Clean Build**: rebuild from scratch.
- **Bundle**: create a distributable game bundle.

Select **Build & Run** and press **F5** to build and launch with debugging. **Just Run** launches the existing build. VS Code writes to `build/defoldkit`; Defold Editor uses `build/default`.

## Coding Style & Naming Conventions

Use two-space indentation and the Lua formatter configured in `.vscode/lua-format.config`, including spaces inside table braces. Lua Language Server supplies editor diagnostics. Follow surrounding naming conventions: snake_case is common for functions and state, while constants use uppercase names. Preserve existing Defold lifecycle callbacks and resource identifiers. Use dotted module imports such as `require("main.scripts.modules.skills")`.

## Testing Guidelines

No automated test suite or coverage threshold is configured. Build and manually exercise changed behavior: movement, abilities, enemy damage, follower behavior, GUI updates, and scene transitions as applicable. Report checks performed and any unverified behavior. Run `git diff --check` before submitting.

## Commit & Pull Request Guidelines

History uses short, informal action summaries such as `add basic_spell script`; no enforced commit prefix is evident. Keep commits focused. PRs should explain the behavior change, link relevant issues, list validation, and include screenshots or video for visible changes. Exclude generated `build/`, `bundle/`, and `.internal/` content.

## Agent-Specific Instructions

If a build is likely to take a long time, provide the command or VS Code task for the user to run and wait for their results. Newly created branches must never track `origin/main` unless the branch itself is named `main`; use `git switch --no-track -c <branch> origin/main` when branching from it.
