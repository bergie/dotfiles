# System-wide agent instructions for bergie

Defaults for all repositories. Project-level `AGENTS.md` files add to or override these rules.

## Context Documents

Reference documents useful across multiple projects are stored in `~/.pi/agent/context/`. These are **not** automatically loaded.

To use a context document, explicitly request it by path:
- `read ~/.pi/agent/context/filename.md`\- `Refer to ~/.pi/agent/context/component-basics.md for NoFlo patterns`

Skills for on-demand capabilities are in `~/.pi/agent/skills/`. Skills are auto-discovered by pi and can be invoked via `/skill:name` or loaded automatically based on their descriptions.

## Work documents

Projects with an `rns://` git remote (rngit repositories, typically as remote `origin`) plan technical work using work documents. The remote URL is the work document repository — the rngit skill auto-discovers it, no need to hardcode.

When planning new work, there should always be a corresponding work document explaining the idea. Before starting a task, check existing work documents (`list --scope active` and `list --scope proposed`) for a relevant document before proposing a new one. When implementing, keep the current task's work document up-to-date by posting updates to it.

- Agents may _propose_ work documents, never _create_ them
- Agents may never mark work documents _completed_ — ask the user instead
- Keep commit status and other session-level remarks out of work document updates — those are handled with the user in the interactive session
- Use the rngit-work skill's scripted client (`scripts/work.js`), never the native `rngit work` CLI — it opens an interactive editor and will hang

## Android/Termux

There are no prebuilt `@biomejs/biome` binaries for Termux, so npm scripts invoking it (e.g. `npm run format`) fail. A locally built `biome` is on `PATH` — substitute it for `npx @biomejs/biome` and keep the script's other arguments as-is.

## Boundaries

Defaults for all code repositories:

- ✅ **Always**: write at least smoketests for any new functionality
- ✅ **Always**: ensure type safety, and verify with the project's type checks
- ✅ **Always**: run the project's formatter after changes to source or tests
- ✅ **Always**: use `git mv` instead of `mv` for renaming files
- ✅ **Always**: keep APIs unambiguous — remove legacy paths instead of adding compatibility layers
- ✅ **Always**: document major changes in the `CHANGELOG.md` (Unreleased segment) where the project maintains one
- ⚠️ **Ask first**: adding dependencies
- ⚠️ **Ask first**: modifying CI configuration
- ⚠️ **Ask first**: adding an optional input to a method
- 🚫 **Never**: commit on your own. When work is ready, summarize the changes and explicitly say "uncommitted changes ready for review" so it's not missed
