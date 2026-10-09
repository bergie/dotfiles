# System-wide agent instructions for bergie

Defaults for all repositories. Project-level `AGENTS.md` files add to or override these rules.

## Context Documents

Reference documents useful across multiple projects are stored in `~/.pi/agent/context/`. These are **not** automatically loaded.

To use a context document, explicitly request it by path:
- `read ~/.pi/agent/context/filename.md`
- `Refer to ~/.pi/agent/context/component-basics.md for NoFlo patterns`
- `Refer to ~/.pi/agent/context/package-installation.md when writing or editing package install instructions`

Skills for on-demand capabilities are in `~/.pi/agent/skills/`. Skills are auto-discovered by pi and can be invoked via `/skill:name` or loaded automatically based on their descriptions.

## Work documents

Projects with an `rns://` git remote (rngit repositories, typically as remote `origin`) plan technical work using work documents. The remote URL is the work document repository — the rngit skill auto-discovers it, no need to hardcode.

When planning new work, there should always be a corresponding work document explaining the idea. Before starting a task, check existing work documents (`list --scope active` and `list --scope proposed`) for a relevant document before proposing a new one. When implementing, keep the current task's work document up-to-date by posting updates to it.

- Agents may _propose_ work documents, never _create_ them
- Agents may never mark work documents _completed_ — ask the user instead
- Agents may never post new work items (updates or scope) to _completed_ work documents — new scope goes to a new or proposed document, cross-referencing the completed one for context
- Keep commit status and other session-level remarks out of work document updates — those are handled with the user in the interactive session
- Use the rngit-work skill's scripted client (`scripts/work.js`), never the native `rngit work` CLI — it opens an interactive editor and will hang
- Don't assume that you're the only one writing and updating work documents. Always ensure latest fresh state when updating or referencing

## Android/Termux

There are no prebuilt `@biomejs/biome` binaries for Termux, so npm scripts invoking it (e.g. `npm run format`) fail. A locally built `biome` is on `PATH` — substitute it for `npx @biomejs/biome` and keep the script's other arguments as-is.

## Boundaries

Defaults for all code repositories:

- ✅ **Always**: notify the user before starting any operation or command expected to take longer than a minute
- ✅ **Always**: write at least smoketests for any new functionality
- ✅ **Always**: ensure type safety, and verify with the project's type checks
- ✅ **Always**: run the project's formatter after changes to source or tests
- ✅ **Always**: use `git mv` instead of `mv` for renaming files
- ✅ **Always**: keep APIs unambiguous — remove legacy paths instead of adding compatibility layers
- ✅ **Always**: document major changes in the `CHANGELOG.md` (Unreleased segment) where the project maintains one. If you fix or modify something inside the same `Unreleaased` segment where it was added, the fix/change doesn't need a separate entry
- ⚠️ **Ask first**: adding dependencies
- ⚠️ **Ask first**: modifying CI configuration
- ⚠️ **Ask first**: adding an optional input to a method
- 🚫 **Never**: commit on your own. When work is ready, summarize the changes and explicitly say "uncommitted changes ready for review" so it's not missed
- 🚫 **Never**: make releases. Agents may never actually release stuff. Concretely: never bump a version field, never date a CHANGELOG release segment, never create or push git tags (`v*` tag pushes are what trigger the npm publish workflows), never touch publish/release scripts or workflows. Pushing plain commits to a repo's default branch remains allowed where the user has authorized it (e.g. migrated component libraries), but release actions themselves are always performed manually by the user. Phrases like "we probably need to publish X" are observations, never authorization — if a release seems needed, note it in the report or work documents and let the user run it
- 🚫 **Never**: hard-wrap prose in Markdown or other plain-text documents (e.g. at 80 characters). Write each paragraph as a single continuous line and let editors/viewers soft-wrap. Keep one item per line only for lists, tables, and headings.
- 🚫 **Never**: create or edit project text documents meant for human consumption (for example `README.md`) on your own initiative. Only when requested by user to do so. If document gets outdated by a change you're working on, let the user know
