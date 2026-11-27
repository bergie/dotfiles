# Uxn/Varvara App Guidelines: Small Screens, Keyboard-First

*Status: proposed convention, not an official Varvara standard. Written for ROM authors and for LLM coding agents writing Uxntal. Where something depends on the emulator or device, it is marked as such.*

## 1. Purpose and design targets

These guidelines describe how to write Varvara ROMs that:

1. Fit and remain fully usable on a **320x240** screen (the T-Deck Max).
2. Assume a **hardware keyboard** is present on that device, so on-screen buttons are optional.
3. **Scale up** gracefully on larger Varvara screens and behave like a good citizen of the wider Varvara ecosystem (themes, metadata, clipboard, mouse support).

The same ROM binary should run unchanged everywhere. Adapt at runtime; never build per-device variants.

## 2. Core principles

- **320x240 is the floor, not the default.** Design the compact layout first, then add to it.
- **Content grows, pixels do not.** On bigger screens show more rows, columns or panels. Do not scale sprites or fonts inside the ROM. Pixel zoom is the host emulator's job.
- **Keyboard complete, mouse optional.** Every action is reachable from the keyboard/controller. The mouse is an enhancement.
- **Never hardcode dimensions.** Derive layout from the screen size you actually have.
- **Degrade, don't break.** Missing mouse, monochrome display, small screen, no theme file: all must still work.
- **Model and view are separate.** The app's state (for a calculator: current value and history) is independent of how much of it the view shows.

## 3. Screen size and layout

### 3.1 Grid

At 320x240 with 8x8 cells you have a **40 x 30** grid. Plan the compact layout in cells.

### 3.2 Requesting and reading the size

The Screen device has writable width and height ports. The pattern is:

1. At reset, optionally request a size by writing `Screen/width` and `Screen/height`.
2. **Read both ports back.** The host may honour, clamp or ignore the request.
3. Lay out from the values you read, never from the values you asked for.

Some emulators resize their window when a ROM writes these ports, and some offer fit modes or mouse-driven resizing, so the size can differ between hosts and sessions.

If your app has a hard minimum, request it explicitly, then verify what you got. If you got less than your minimum, show a clear "screen too small" state rather than drawing garbage.

### 3.3 Detecting changes

There is no dedicated resize event in the base spec. Portable approach:

- Cache the last-seen width and height.
- In the screen vector (runs every frame), compare the current ports to the cache.
- If either changed, recompute the layout and force a full redraw. Otherwise do nothing.

### 3.4 Layout tiers

Define a small number of tiers and pick one from the current size. A suggested split:

| Tier | Condition | Typical behaviour |
| --- | --- | --- |
| Compact | width <= 320 or height <= 240 | Single pane, no chrome, minimal status line |
| Regular | larger than compact | Add secondary panes, more history, optional header |
| Large | much larger | More columns, side panels, comfortable spacing |

Keep the number of tiers small (two or three). Test every tier. The exact thresholds are yours to choose, but the compact tier must be derived from 320x240.

### 3.5 Scaling up

Prefer these when extra space appears, roughly in this order:

1. Show more of the content (rows, history, columns).
2. Add secondary information (status, hints, previews).
3. Add optional controls for mouse users.
4. Add whitespace and margins last.

## 4. Keyboard-first input

- Handle input through the Controller device: the key port for characters and the button byte for navigation and modifiers.
- Provide a complete keyboard path for every function. Document it.
- Do not rely on hover, drag or right-click for anything essential.
- **Check before relying on modifier chords.** Varvara reports modifiers through the Controller/button byte (Ctrl is \`0x01\`, Alt is \`0x02\`, Shift is \`0x04\`, Home is \`0x08\`), while Controller/key holds the character and is cleared after the vector runs. Whether the T-Deck Max port maps its keyboard this way needs to be verified on hardware. Prefer single keys, or simple prefix schemes, for important actions.
- Make key bindings discoverable, e.g. a help overlay on a single key.
- Declare shortcuts in the Varvara **manifest** structure (the manifest.tal support library). It maps controller input, a button byte plus a key, to functions in the rom, for example Ctrl+c to copy. The manifest's address is exposed through metadata field \`a0\` (see 7.1).

### 4.1 Optional on-screen controls

When a mouse is present and the layout tier allows it, you may reveal buttons and clickable affordances. Detect the mouse by observing real mouse activity, not by assuming. On the T-Deck they never appear, and the app must feel complete without them.

**Worked example (calculator):** the model holds the current entry and a history list. In the compact tier, the view is just the current entry plus as many history lines as fit, driven entirely by the keyboard. In larger tiers with a mouse, the same view adds an on-screen keypad. The model and key handling are identical in both.

## 5. Color, themes and legibility

- Support the Varvara `.theme` standard: a `.theme` file starts with 6 bytes encoding the RGB values of 4 colors.
- The spec defines no named color roles, so pick one assignment and keep it across your apps, and do not assume color 0 is the light one: the example theme on the theme page has color 0 black and color 3 white. For example: color 0 as background (the foreground layer treats color 0 as transparent) and 1 for text. Monochrome hosts show colors 0 and 2 as black and 1 and 3 as white, so use 2 and 3 only for emphasis that stays readable when they fall back to the tones of 0 and 1. Show selection by inversion, not by color 2 or 3. Four colors are enough for any interface.
- **Stay legible in two tones.** Monochrome emulators display colors 0 and 2 as black, and 1 and 3 as white. Never depend on two colors that collapse to the same tone.
- Do not encode meaning in color alone. Add position, a glyph, underline or inversion.
- Load the theme at start and fall back to the defaults if there is no file.

### 5.1 Visual style

The constraints above (four colors, two-tone legibility, an 8px grid) already push toward the plain, high-contrast, humanist look of the original Mac, which is also the look of Hundred Rabbits' own Varvara apps. This section recommends that style so apps feel like one family on the T-Deck and sit comfortably beside existing roms on a desktop. It is guidance, not a requirement: themes and two-tone legibility are the hard rules, and an app with a good reason to differ is not non-compliant.

- **Grid:** align all chrome and text to the 8px cell grid, so layouts stay predictable across the layout tiers.
- **Selection:** show it by inversion, not by color.
- **Chrome:** keep it minimal and consistent. Use 1px borders and rounded corners drawn from a small shared set of tiles. Add no decoration that carries no meaning.
- **Spacing:** be generous in the compact tier. A screen with a few fewer rows reads better than a cramped one.
- **Icons:** draw the 24x24 metadata icon (7.1) in the same style, since launchers will show them side by side.
- **Assets:** if you reuse tiles or fonts from other projects instead of drawing your own, check their license first.

## 6. Behaviour on a small, battery-powered device

- **Redraw only when something changed.** The screen vector fires every frame. Keep a dirty flag and return early when it is clear.
- Avoid constant animation. Prefer state changes that are visible and calm. This also helps slow-refresh or low-contrast displays.
- Do not poll files or devices every frame. Use events, timers or explicit refresh keys.
- Keep memory use modest. Do not assume large banks of memory exist.

## 7. Ecosystem conventions

- **Metadata:** every rom ships a metadata block and registers it at reset, as a first instruction. Details in 7.1.
- **Clipboard:** use the `.snarf` file convention for cut, copy and paste.
- **Themes:** see section 5.
- **Manifest:** see section 4.
- **Persistent state:** keep it in plain text files via the File device, laid out as described in 7.2. Never assume an absolute path layout.
- **Debug info:** keep symbol files from your build so tools can debug the rom.

### 7.1 Metadata

Every ROM should carry a metadata block. It lets launchers, stores and tools show a name, a description and an icon without running the ROM. On a 320x240 launcher list this is the only identity the app gets, so fill it in properly. Source: the [Varvara application support standards](https://wiki.xxiivv.com/site/libraries.html).

**How it is found.** The ROM writes the address of its metadata block to the System device's metadata port (`06`), which informs the emulator; the emulator may use it or ignore it. External tools find the block without running the ROM: a compatible rom must begin with `a0`, a two-byte address, then `80 06 37`. That is what `;meta #06 DEO2` assembles to as the first instruction of the reset vector, so it must come first. The address is absolute in memory, so a tool reading the rom file must add the `0x100` zero-page offset.

**Format.**

- One version byte (typically `00`), then zero-terminated text.
- The text holds the program name on the first line, then details such as a description, author and date, each on its own line (`0a`).
- The whole block should be at most 256 bytes.
- Then one byte with the number of fields (`00` if none). Each field is an identifier byte followed by a value short.
- Documented fields: `56` is the Varvara version (the wiki's example uses `0050`, which is 80, the version on the spec page), `83` is a 24x24 icon in the chr format, `a0` is the application manifest (section 4), and `f0` is the muxn API. Other identifiers are free for anything else the rom wants to reveal.

**Example** (adapted from the wiki's example):

```
|0100

@on-reset ( -> )
	;meta #06 DEO2  ( first instruction: the rom must begin a0 hb lb 80 06 37 )
	( ...screen, theme and vector setup follows... )
	BRK

@meta 00
	"Calc 0a "Keyboard-first 20 "calculator 00
	01
	56 0050  ( Varvara version; add 83 =appicon for an icon )
```

**Guidelines.**

- Name: short enough to read in a compact launcher list. Put the description, author and date on the following lines, and keep the whole block under 256 bytes.
- Include the Varvara version field and, where you can, the 24x24 icon (`83`), so launchers can show it. Draw the icon so it still reads in two tones (section 5).
- If you declare shortcuts, point field `a0` at your manifest (section 4).
- Keep the name stable across versions, since launchers and stores will key on it.
- The metadata lives inside the rom, so the program can read it too. It is advisory: the ROM must behave identically if the host ignores it.

### 7.2 Data storage

Store data as plain text files, one record per file, in a Maildir-style layout: a directory per collection, one small file per item. This is a recommendation for all ROMs that keep user data, so that data stays readable, greppable, easy to sync and safe from partial writes.

**Why this layout.**

- A damaged or half-written file loses one record, not the whole dataset.
- Two writers rarely touch the same file, so syncing between devices has few conflicts.
- People and tools can read, edit and back up the data without the ROM.
- Access can be scoped per directory.

**Rules.**

- Use plain text, UTF-8 where possible. Binary formats need a stated reason (the `.theme` file is one).
- One record per file. Do not keep a shared mutable index that every write must update. Rebuild any index from the files.
- Name files uniquely and sortably, for example a timestamp or counter plus a short id. Use no spaces and do not depend on upper or lower case.
- A record is a few `key: value` header lines, a blank line, then the body.
- Keep each file small enough to read into a modest buffer. Read large content, such as books, in chunks.
- Keep a ROM's data inside its working directory, which is as far as the File device reaches, and put each collection in a subdirectory. Document the paths you read and write.
- Treat configuration the same way: a plain text file of `key value` lines.

**Adapting Maildir to the File device.** Classic Maildir delivers a message by writing it into a temporary directory and then renaming it into place, and records state such as read or unread in the file name. The File device in the current Varvara spec (80K) offers name, read, write, append, delete and stat operations. Writing to a file that does not exist creates it, and writing to `File/name` closes the previously opened file or directory. Reading a directory returns one line per entry: four characters of details, a tab, the name and a line break, with a trailing `/` on directories. The device cannot reach outside the working directory. The spec has no rename and no create-directory operation, so:

- Write each record in one pass and end it with a clear terminator, such as a final marker line. Readers skip any file without it.
- To move a record, write the complete record under its new name, then delete the old one. A crash in between leaves a duplicate, never a loss, so readers must tolerate duplicates.
- Keep state in small separate files or in a header line, instead of in the file name.
- Treat creating directories as part of installation, not something the ROM relies on at run time. The spec does not say whether a write can create one.

**Host notes (for implementers).** A host may offer guarantees the spec does not require, as long as no ROM depends on them. The most useful is atomic replace: a write with `File/append` at `0x00` replaces the file's contents, and writing to `File/name` closes the open file, so a host can stage the write in a temporary file and rename it over the original at that close. ROMs see no difference, and a crash mid-write leaves the old file intact. Rename or make-directory calls could be added on one of the two reserved devices, but a ROM that uses them will not run on other hosts, so keep them out of portable ROMs. Varvara also defines two File devices, which lets a ROM read from one collection while writing to another.

## 8. Authoring and tooling discipline

These conventions keep source files maintainable for humans and reduce context size, stack-tracking errors, and retry loops for LLM coding agents.

### 8.1 Modularity and file size

- **Keep `.tal` modules small (under ~200 lines).** Split UI rendering, application model/state, and File/device I/O into separate files joined by `~include` directives. Small files let both human authors and coding agents read and patch a single concern without loading the whole ROM.
- **Keep model, view, and I/O in separate modules.** This reinforces section 2 and makes state logic testable without a Screen device.
- **Generate bulk data externally.** Never hand-author or LLM-generate large `.chr`/`.icn` sprite tables, font bitmaps, or lookup tables inline. Emit them from small, deterministic host scripts (Node.js or Python) and include the resulting binary or literal file.

### 8.2 Stack signatures and assembly hygiene

- **Annotate every routine with a Forth-style stack signature**, e.g. `@draw-cell ( x* y* glyph* -- )`. Treat the signature as a contract: every return path (`JMP2r`) must leave the working and return stacks matching the declaration.
- **Avoid zero-page rewinding after code emission.** Define all zero-page variables (`|0000`) and device port constants before `|0100`. Never rewind the program counter back into zero-page after emitting instructions, as it silently overwrites ROM bytes.
- **Prefer explicit relative conditional jumps (`?&label`)** over manual address arithmetic on `JCN`.

### 8.3 Automated testing with TAP

- **Verify non-UI logic headless via TAP.** Write unit tests using the Test Anything Protocol (`ok` / `not ok` lines printed to Console/write `#18 DEO`, exiting via System/state `#010f DEO` on failure) and run them under `uxncli`.
- **Test modules in isolation.** Build lightweight test harnesses that `~include` only the target module and a minimal `tap.tal` helper rather than booting the full UI ROM.
- **Wrap assemble-and-test in a single quiet command.** Run `uxnasm` followed by `uxncli`, suppressing output on pass and emitting only the compiler error or failing TAP diagnostic on failure.

## 9. Testing checklist

Run every ROM through all of these before release:

- [ ] 320x240, keyboard only, no mouse
- [ ] A typical desktop window size
- [ ] A very large window
- [ ] Resizing while running (where the host allows it)
- [ ] Monochrome / two-tone rendering
- [ ] No `.theme` file present, and a custom `.theme` present
- [ ] Every function reachable from the keyboard
- [ ] No redrawing or file access when idle
- [ ] On the real device, including modifier-key behaviour

* [ ] Metadata present: name, description, Varvara version and icon, registered as the first instruction at reset

- [ ] User data stored as one plain text record per file under the ROM's own directory, with incomplete files skipped on read
- [ ] Every routine declares a valid `( before -- after )` stack signature
- [ ] Model and parser routines pass headless TAP tests under `uxncli`

