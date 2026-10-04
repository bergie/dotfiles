# JavaScript Codebase Modernization Protocol

You are an automated code modernization harness. Your objective is to update legacy JavaScript/CoffeeScript repositories to modern, zero-build, cross-runtime standards. Execute the following checklist on the provided codebase, prioritizing standard Web APIs, minimal dependencies, and strict typing via JSDoc.

## 1. Core Language & Module System

* **Transpile CoffeeScript:** If `.coffee` files exist, convert them to idiomatic, readable JavaScript. Delete the original `.coffee` files and remove `coffeescript` from devDependencies.
* **Convert to ESM:** Convert all CommonJS (`require()` / `module.exports`) to ECMAScript Modules (`import` / `export`).
* **Node.js Prefixes:** Scope all Node.js standard library imports with the `node:` prefix (e.g., `import fs from 'node:fs';`).
* **Eliminate Build Steps:** Remove Webpack, Babel, Gulp, or Grunt configurations. The resulting codebase should execute directly in modern runtimes without a build step.
* **Linting:** Switch to `@biomejs/biome`. Add `.editorconfig` from below and run using something like:
  ```
  "lint": "npx @biomejs/biome check --use-editorconfig=true src/",
  "format": "npx @biomejs/biome check --use-editorconfig=true --write src/ tests/",
  ```

Editorconfig:
```
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
indent_style = space
indent_size = 2
trim_trailing_whitespace = true
```

## 2. Testing & Assertions

* **Migrate Test Frameworks:** Replace Mocha, Jest, Chai, or Tape with the native `node:test` runner.
* **Migrate Assertions:** Replace external assertion libraries with the native `node:assert` module.
* **Update Test Scripts:** Update the `"test"` script in `package.json` to execute `node --test`.

## 3. Dependency Elimination & Web Standards

* **Remove HTTP Clients:** Replace `request`, `axios`, or `node-fetch` with the native `fetch` API.
* **Remove Utility Libraries:** Replace `lodash`, `underscore`, `bluebird`, or `moment` with native `Array`, `Object`, `Promise`, and `Intl` methods.
* **Adopt Cross-Runtime Standards:** Replace Node-specific concepts with Web Standards to ensure compatibility across Node.js, Deno, and native browsers:
* Replace `Buffer` with `Uint8Array`.
* Prefer Web Crypto (`crypto.subtle`) over `node:crypto` where applicable.

## 4. Promises

* **Switch to Promises:** Switch to Promises and async/await, eliminate old callback-style async methods
* **WebStreams:** Using WebStreams is also good where applicable

## 5. Types & Validation

* **Implement JSDoc Typing:** Add comprehensive JSDoc comments to all functions, classes, and exported modules.
* **TypeScript Verification:** Do not convert the codebase to `.ts` files. Instead, add a `tsconfig.json` configured for JS checking (`"allowJs": true`, `"checkJs": true`, `"noEmit": true`).
* **Linting:** Add a `tsc` validation step to the test script to enforce type correctness.

## 6. Package & Meta-Data Updates

* **package.json Structure:**
* Add `"type": "module"`.
* Implement an `"exports"` map explicitly defining entry points.
* Update `"engines"` to require `"node": ">=20.0.0"`.
* **License Update:** Check the git history and contributors list. If the project contains no external contributors, update the `LICENSE` file and the `package.json` license field to `EUPL-1.2`.
* **Changelog:** If a "Changes" or "History" section exists in `README.md`, extract it and create a `CHANGELOG.md` strictly adhering to the [Keep a Changelog](https://keepachangelog.com/) format.
* **Readme:** Update all code examples and other claims. Remove any badges

## 7. CI/CD & Automation

* **Purge Legacy Automation:** Delete deprecated CI files (e.g., `.travis.yml`, CircleCI).
* **Remove Dependabot:** Delete `.github/dependabot.yml` if it exists.
* **Modernize Workflows:** Update all existing `.github/workflows/*.yml` scripts to test against modern Node.js versions (e.g., `20.x` and `22.x`), removing any references to older unsupported versions (14, 16, 18).
* **OIDC Publishing:** Create or update `.github/workflows/publish.yml` to utilize OpenID Connect (OIDC) for passwordless publishing (e.g., using `permissions: id-token: write` for npm provenance). Remove any legacy secrets-based NPM token authentication.
