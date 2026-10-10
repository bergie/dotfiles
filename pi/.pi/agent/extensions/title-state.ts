/**
 * Title State Extension
 *
 * Reflects the agent state in the terminal title (OSC 0), which tmux picks up
 * via `pane_title` and shows in window names with `automatic-rename-format`.
 *
 * Unlike OSC 7501 program status (which pi also reports), the plain title is
 * forwarded by tmux, so this works inside tmux windows.
 *
 * Markers:
 *   ⏸  pi is waiting for user input (blocking extension dialog)
 *   ●  agent run or compaction in progress
 *   ✓  last run finished
 *   ✗  last run ended with an error
 *   (none) idle
 */

import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type State = "idle" | "working" | "done" | "error";

const MARKERS: Record<State, string> = {
	idle: "",
	working: "● ",
	done: "✓ ",
	error: "✗ ",
};

function firstLine(text: string | undefined): string {
	return text?.split(/\r?\n/, 1)[0]?.trim() ?? "";
}

export default function (pi: ExtensionAPI) {
	let state: State = "idle";
	let lastError: string | null = null;
	let promptDepth = 0;

	function title(): string {
		const cwd = path.basename(process.cwd());
		const session = pi.getSessionName();
		const base = session ? `π - ${session} - ${cwd}` : `π - ${cwd}`;
		// Blocked prompts take precedence so "awaiting input" stays visible.
		if (promptDepth > 0) return `⏸ ${base}`;
		const marker = MARKERS[state];
		return lastError ? `${marker}${base} — ${lastError}` : `${marker}${base}`;
	}

	function refresh(ctx: ExtensionContext) {
		ctx.ui.setTitle(title());
	}

	pi.on("agent_start", async (_event, ctx) => {
		state = "working";
		lastError = null;
		refresh(ctx);
	});

	pi.on("message_end", async (event) => {
		if (event.message.role !== "assistant") return;
		if (event.message.stopReason === "error") {
			lastError = firstLine(event.message.errorMessage) || "Error";
		}
	});

	pi.on("session_before_compact", async (_event, ctx) => {
		if (state === "idle") state = "working";
		refresh(ctx);
	});

	pi.on("session_compact", async (_event, ctx) => {
		if (state === "working") state = "done";
		refresh(ctx);
	});

	pi.on("session_compact_failed", async (event, ctx) => {
		if (event.aborted) {
			if (state === "working") state = "idle";
		} else {
			state = "error";
			lastError = firstLine(event.errorMessage) || "Compaction failed";
		}
		refresh(ctx);
	});

	pi.on("agent_settled", async (event, ctx) => {
		state = event.aborted ? "idle" : lastError ? "error" : "done";
		refresh(ctx);
	});

	// Blocking extension dialogs (confirmations, inputs, editors): the exact
	// "awaiting input" signal, including core prompts like tool permission gates.
	pi.on("ui_prompt_start", async (_event, ctx) => {
		promptDepth += 1;
		refresh(ctx);
	});

	pi.on("ui_prompt_end", async (_event, ctx) => {
		promptDepth = Math.max(0, promptDepth - 1);
		refresh(ctx);
	});

	pi.on("session_info_changed", async (_event, ctx) => refresh(ctx));

	pi.on("session_start", async (_event, ctx) => {
		state = "idle";
		lastError = null;
		promptDepth = 0;
		refresh(ctx);
	});

	pi.on("session_shutdown", async (_event, ctx) => {
		state = "idle";
		lastError = null;
		promptDepth = 0;
		refresh(ctx);
	});
}
