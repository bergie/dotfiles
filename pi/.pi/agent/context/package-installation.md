# Package installation: rngit releases first

How to document installation of first-party packages. Applies whenever you write or edit READMEs, setup instructions, CI publish steps, or generated install snippets for our packages.

## Principle

First-party packages — `@reticulum/*` (reticulum-js), `dacar`, `noflo`, `rfed`, and the meri-imperiumi `signalk-*` plugins — are canonically distributed as **cryptographically signed rngit releases** over the Reticulum mesh. The centralized registries (npm, JSR, PyPI) are **mirrors** of those releases.

Therefore, install instructions for first-party packages always show, in this order:

1. **rngit releases** (canonical, signed)
2. **Centralized registries** (npm / JSR / pip) as convenience fallback for users without mesh access

Never remove or demote the mesh section when editing install docs, and keep versions consistent between the two sections.

## The mesh install path

Requires [Reticulum](https://reticulum.network) installed (the `rngit` CLI ships inside RNS). Two commands, no package manager integration needed:

```sh
# Fetch and verify a signed release into the current directory.
# <signer> is the release signer's Reticulum identity hash — pin it in the README.
rngit release fetch rns://<origin>/<group>/<repo> "v<version>:*" <signer>

# Then install the verified artifact with the native tool:
pip install ./*.whl        # Python packages
npm install ./*.tgz        # npm packages
```

Real example (`rfed-python` on the rngit node, signer hash placeholder):

```sh
rngit release fetch rns://3ea5aad068a337670f5bb8073226adb4/public/rfed-python "v0.1.0:*" <signer>
pip install ./rfed-0.1.0.tar.gz
```

Useful extras:

- `rngit release list rns://...` and `rngit release latest rns://...` discover available releases
- `rngit release verify <manifest.rsm> ... --offline` re-validates downloaded artifacts without network
- The fetched artifacts form an offline-installable set (`pip install --no-index --find-links .` / npm local tarballs)

Bootstrapping note: this path needs only `rngit` itself — the wrapper tools (`rns-pip`, `npm-rns`, proposed in dotfiles work documents #2/#3) are convenience layers, never prerequisites.

## Rules for LLM implementers

- **Ordering is mandatory**: rngit first, registries second. If an install section lacks the mesh path, add it.
- **Pin the signer**: every README documents the release signer identity hash next to the fetch command, so users verify rather than trust.
- **New first-party package** ⇒ it must produce signed rngit releases at tag time and its README documents the mesh install. Tooling status lives in the dotfiles work documents (#2 rns-pip, #3 npm mirror, #4 universal canonical releases) — check `work.js list` on the dotfiles board before assuming a capability exists.
- **Don't invent syntax**: the only canonical commands are `rngit release fetch`, `verify`, `list`, `latest`, `view` — check `rngit release --help` when unsure. Target format is `"<tag>:<artifact-glob>"` (fnmatch, `all` fetches everything).
- **Registry fallback stays**: npm/JSR/pip sections are correct and wanted — they serve users without mesh access and the Signal K appstore-style consumers. Framing: canonical vs mirror, never deprecated vs recommended.
