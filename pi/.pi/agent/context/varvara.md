# Varvara device reference

Offline reference for the Varvara device layer, condensed from the specification at https://wiki.xxiivv.com/site/varvara.html (version 80K, retrieved 2026-11-28). The wiki page is the source of truth — this document exists so the machine details are available without a network round-trip. Device tables reproduce the factual port layouts; all explanatory text is written fresh.

For how to build against this: `uxn-app.md` governs everything inside a ROM; `uxn-utility.md` governs the ROM/host boundary. The parts of this reference those documents lean on are the File device (mailboxes), the Screen size ports (layout tiers), the Controller button bits (input policy), and the System metadata port (rom identity).

## Machine model

A Uxn machine addresses 64 KB directly: the first 256 bytes (`0x0000`–`0x00ff`) serve double duty as the zero page for variables **and** the device page — device registers are memory-mapped over that same region, which is why zero-page variables and device port constants must be laid out so they never collide (see uxn-app §8.2). Program code loads from `0x0100`.

Each device owns 16 bytes of registers, called **ports**. A port that carries a 16-bit value occupies two consecutive bytes; the tables below treat such pairs as one row. Ports that hold a code address evaluated on device events are called **vectors**.

Memory beyond the 64 KB is reachable only through `System/expansion`: banks of 65536 bytes, ideally 16 of them. No operation crosses a bank boundary — the largest legal transfer ends at the last byte of a bank, which matters when buffering file reads.

| Page | Device | Page | Device |
| --- | --- | --- | --- |
| `00` | System | `80` | Controller |
| `10` | Console | `90` | Mouse |
| `20` | Screen | `a0` | File 1 |
| `30` | Audio 0 | `b0` | File 2 |
| `40` | Audio 1 | `c0` | Datetime |
| `50` | Audio 2 | `d0` | Reserved |
| `60` | Audio 3 | `e0` | Reserved |
| `70` | unassigned | `f0` | Reserved |

Reserved pages exist for implementations to experiment with; a portable ROM never touches them.

## System — `00`

```
|00 @System $2 &expansion $2 &wst $1 &rst $1 &metadata $2 &r $2 &g $2 &b $2 &debug $1 &state $1
```

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `00` | short | v | Unused in the base spec |
| `expansion` | short | w | Points at an expansion operation record (below) |
| `wst` | byte | r/w | Working stack pointer: reading yields the depth, writing rewinds |
| `rst` | byte | r/w | Return stack pointer, same deal |
| `metadata` | short | w | Address of the rom's metadata block (uxn-app §7.1); advisory — the emulator may ignore it |
| `r`, `g`, `b` | short | w | Theme channels; the screen derives its four colors from them |
| `debug` | byte | w | Debug hooks; `#01` dumps both stacks |
| `state` | byte | w | Termination: a non-zero value at the end of any vector stops the program. Exit code is the value's `0x7f` portion — `0x01` signals failure, `0x80` success |

### Expansion

An operation record is one op byte plus fields, written into memory; pointing `expansion` at it runs it. Useful for caching file content in banks or for bulk memory setup.

| Op | Name | Fields | Effect |
| --- | --- | --- | --- |
| `00` | fill | length*2, bank*1, addr*2, value*1 | Repeat `value` across `length` bytes |
| `01` | cpyl | length*2, src bank*1, src addr*2, dst bank*1, dst addr*2 | Copy forward, first byte first |
| `02` | cpyr | length*2, src bank*1, src addr*2, dst bank*1, dst addr*2 | Copy backward, last byte first |

The forward/backward pair exists so overlapping regions can be copied safely in either direction.

### Theme

The three shorts carry 4 bits per channel each. Writing a `.theme` file's 6 bytes here (as loaded at startup, uxn-app §5) is the standard way to take on the user's palette; a ROM should still function if it never does.

## Console — `10`

```
|10 @Console/vector $2 &read $5 &type $1 &write $1 &error $1
```

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Runs once per received byte |
| `read` | 5 bytes | r | The incoming byte(s), valid only inside the vector |
| `type` | byte | r | Queue classification, values below |
| `write` | byte | w | Push one byte to stdout |
| `error` | byte | w | Push one byte to stderr |

The `type` byte classifies the stream: `0` nothing queued, `1` stdin, `2` argument text, `3` the space between two arguments, `4` end marker. Spacers and end markers are always line feeds. When command-line arguments exist, the vector fires for them before the reset vector ever runs — a ROM that inspects arguments must be prepared for that ordering.

The wiki port table also shows ports `0x1c` (`addr`), `0x1e` (`mode`) and `0x1f` (`exec`) that the spec text never describes — apparently an in-progress console expansion. Treat them as undocumented and reserved; a portable ROM must not rely on them.

Output is strictly byte-at-a-time: printing a string means one `DEO` per character, typically in a walk-the-string loop.

The utility profile allows a host to drop a byte into console input as an optional wake signal (uxn-utility §7.6, O12); a ROM must work without ever receiving one.

## Screen — `20`

```
|20 @Screen/vector $2 &width $2 &height $2 &auto $2 &x $2 &y $2 &addr $2 &pixel $1 &sprite $1
```

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Fires 60 times per second, unconditionally |
| `width` | short | r/w | Requested on write; always reports the true value on read |
| `height` | short | r/w | Same contract as width |
| `auto` | byte | w | Auto-advance mode for repeated draws (below) |
| `x`, `y` | short | w | Drawing position, signed |
| `addr` | short | w | Address of the sprite data to draw |
| `pixel` | byte | w | Plot or fill operation (below) |
| `sprite` | byte | w | Blit operation (below) |

Two compositing layers sit over the theme palette. The foreground layer treats color0 as transparent, which is why color0 doubles as the background/erase color in every layer operation.

The size ports carry an asymmetry worth internalizing: writing is a *request* the host may honour, clamp or refuse, but reading always reflects reality. All layout decisions must come from the read-back values — this is exactly the pattern uxn-app §3.2 prescribes, and there is no resize callback in the base spec, so change detection is the ROM's own job (compare against cached values each frame).

The vector rate is fixed: 60 Hz whether or not anything needs doing. An idle ROM therefore earns its battery life by testing a dirty flag and returning immediately (uxn-app §6).

### Pixel operations

The `pixel` byte packs layer, mode and color:

```
bit 7  fill (1 = fill to screen edges, 0 = single pixel)
bit 6  layer (1 = foreground, 0 = background)
bit 5  flip fill vertically
bit 4  flip fill horizontally
bits 0-1  color (0-3)
```

A fill extends from the current x,y to the screen edge; the default direction is down-right, and the flip bits pick the other three quadrants.

### Sprite operations

The `sprite` byte is shaped the same way, with the color field widened:

```
bit 7  2bpp mode (1 = two bits per pixel, 0 = one)
bit 6  layer (1 = foreground, 0 = background)
bit 5  flip sprite vertically
bit 4  flip sprite horizontally
bits 0-3  color mapping (below)
```

Sprite data lives in ordinary memory; `addr` points at it, 8 bytes per 1bpp sprite, 16 per 2bpp. In 1bpp mode bits 0–1 choose the colors for set and unset pixels. In 2bpp mode the four bits map the four pixel values to palette entries, and mapping values divisible by 5 (`0`, `5`, `a`, `f`) render those pixels transparent instead — that trick is how 2bpp artwork gets holes punched in it.

### Auto mode

`auto` makes one write draw several sprites:

```
bit 7-4  count (0 = draw one, 0xf = draw sixteen)
bit 3  advance address per sprite
bit 2  advance downward (column of sprites)
bit 1  advance rightward (row of sprites)
bit 0  unused
```

With the address bit clear, every sprite in the run is a repeat of the same data; with it set, `addr` walks forward 8 bytes (1bpp) or 16 (2bpp) per sprite, which is how tiles stream out of a tile sheet. Direction flips reverse the walk.

## Audio — `30`, `40`, `50`, `60`

```
|30 @Audio0/vector $2 &position $2 &output $1 &pad $3 &adsr $2 &length $2 &addr $2 &volume $1 &pitch $1
```

Four identical voices. Samples are unsigned 8-bit mono PCM in memory.

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Fires when the current note finishes |
| `position` | short | r/w | Playback cursor inside the sample |
| `output` | byte | r | Envelope loudness right now |
| `adsr` | short | w | Four 4-bit envelope stages: attack, decay, sustain, release |
| `length` | short | w | Sample length in bytes |
| `addr` | short | w | Sample start address |
| `volume` | byte | w | Stereo balance, 4 bits per channel; `#ff` is full on both |
| `pitch` | byte | w | Note to play; the top bit plays the sample once instead of looping |

Each envelope stage is measured in fifteenths of a second, so `#ffff` spans four seconds, one per stage, linearly interpolated: silent to full (attack), full to half (decay), held at half (sustain), half to silent (release). `adsr` of `#0000` skips the envelope entirely, which pairs with the one-shot pitch bit for playing long samples through.

The audio device is the least portable corner of Varvara — the recommended emulator build omits it entirely — so a utility ROM should never depend on it.

## Controller — `80`

```
|80 @Controller/vector $2 &button $1 &key $1
```

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Fires on any press or release, and on key presses |
| `button` | byte | r | Live state of the eight buttons (below) |
| `key` | byte | r | The character typed, valid only during the vector; zeroed afterwards |

Button bits:

| Bit | Game button | Modifier reading |
| --- | --- | --- |
| `0x01` | A | Ctrl |
| `0x02` | B | Alt |
| `0x04` | Select | Shift |
| `0x08` | Start | Home |
| `0x10` | Up | — |
| `0x20` | Down | — |
| `0x40` | Left | — |
| `0x80` | Right | — |

The design treats gamepad and keyboard as one device: arrows arrive as button bits, letters as `key`, and held modifiers appear in the high nibble alongside the character. Because `key` is wiped after each vector, the chord is only observable inside the handler — a ROM that needs "Ctrl was held when this key arrived" must read both ports in the same invocation (this is the assumption uxn-app §4 flags for on-device verification). Port 4 (`player`, byte) tags the source player when several controllers exist.

## Mouse — `90`

```
|90 @Mouse/vector $2 &x $2 &y $2 &state $1 &pad $3 &scrollx $2 &scrolly $2
```

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Movement, or button change |
| `x`, `y` | short | r | Position, signed |
| `state` | byte | r | Low nibble holds buttons; primary alone reads `01`, primary+tertiary `05` |
| `scrollx`, `scrolly` | short | r | Wheel deltas, ±1 as `0001`/`ffff`, both zeroed after the vector |

The `scrollx`/`scrolly` shorts sit at ports `0x9a`/`0x9c`. (The wiki port table also marks a short labelled `z` at port `0x98` that the spec text never explains — treat it as reserved.)

Nothing guarantees a mouse exists. The honest way to offer pointer affordances is to watch for genuine vector activity and reveal them only then, which is the detection rule uxn-app §4.1 sets for optional on-screen controls.

## File — `a0` and `b0`

```
|a0 @File1/vector $2 &success $2 &stat $2 &delete $1 &append $1 &name $2 &length $2 &read $2 &write $2
|b0 @File2/vector $2 &success $2 &stat $2 &delete $1 &append $1 &name $2 &length $2 &read $2 &write $2
```

Two independent devices, letting a ROM read one file while writing another — the mechanism behind copy-then-delete moves and read-from-inbox/write-to-outbox flows.

| Port | Size | Dir | Meaning |
| --- | --- | --- | --- |
| `vector` | short | v | Reserved for future removable-media support; no spec yet |
| `name` | short | w | Address of a zero-terminated path; also the close operation (below) |
| `length` | short | w | Buffer size for the next read, write or stat |
| `success` | short | r | Byte count of the last operation; `0000` means failure, or end of data while reading |
| `stat` | short | w | Write a buffer address to receive the four detail characters for the named file |
| `delete` | byte | w | Any write removes the named file; `success` reports `0001` or `0000` |
| `append` | byte | w | `0x01` makes writes extend the file; `0x00` makes the first write replace it |
| `read` | short | w | Write a buffer address to pull up to `length` bytes into memory |
| `write` | short | w | Write a buffer address to push up to `length` bytes into the file |

The operating pattern is: set `name` to open (implicitly closing whatever was open — that write *is* the close), set `length`, then write a memory address into `read` or `write` to perform the transfer; `success` says how much actually moved.

Details the mailbox protocol builds on (uxn-utility §7.6):

- **Chunking.** Reads and writes continue from where the last one stopped, so a large file is consumed one buffer at a time; there is no seek.
- **Replace-on-write.** With `append` clear, the first write to a name overwrites the file's entire previous content — the hook a host can implement as stage-to-temp-then-rename, giving ROMs atomic replacement without knowing it.
- **Creation.** Writing to a name that doesn't exist creates it. Nothing in the spec promises directory creation, which is why the host, not the ROM, builds the mailbox tree.
- **Sandbox.** Paths cannot escape the ROM's working directory; that directory *is* the exchange root.
- **Clamping.** A length beyond working memory is trimmed to what fits.
- **No rename, no mkdir, no move.** Composite operations (copy then delete) are the only way to relocate a record, and a crash between the halves leaves a duplicate — readers must tolerate that.

### Directory listings

When `name` points at a directory, `read` returns one line per entry:

```
001a	file.txt
????	large file.mp4
----	directory/
```

Each line is four detail characters, a **tab** separator, the entry name, and a line feed. The tab (introduced in 79K, replacing a space) keeps the format machine-parseable and preserves names containing spaces. Directory entries end in `/`.

Detail characters: `0`–`f` give the file size in hex, zero-padded to always include the lowest nibbles; `-` marks a directory; `?` marks a file over 64 KB; `!` marks a missing file. `stat` returns the same four characters for a single named file, padded with zeros (files) or dashes (directories) to the requested length. Since the listing order is unspecified, a reader that needs deterministic order — as the mailbox reader does when picking the oldest message — must sort the names itself.

## Datetime — `c0`

```
|c0 @DateTime/year $2 &month $1 &day $1 &hour $1 &minute $1 &second $1 &dotw $1 &doty $2 &isdst $1
```

| Port | Size | Range |
| --- | --- | --- |
| `year` | short | full year |
| `month` | byte | 0–11 |
| `day` | byte | 1-based — the only non-zero-based field |
| `hour`, `minute`, `second` | byte | 0-based |
| `dotw` | byte | weekday, Sunday = 0 |
| `doty` | short | day of year, 0-based |
| `isdst` | byte | DST flag |

The zero-based month is the classic off-by-one here: any date formatter in a ROM must add one before display (uxn-utility §7.9 formats all dates host-side, which sidesteps it entirely).

## Version history

- **79K**: directory listings switched from a space to a tab between the detail characters and the file name, fixing parsing of names that contain spaces.
- **80K**: current baseline; the version the utility profile pins in its metadata field `56`.
