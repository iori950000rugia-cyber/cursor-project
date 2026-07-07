# AGENTS.md

## Cursor Cloud specific instructions

This repository contains a single product, `genshin-builder/` — a **build-free static web app** (vanilla HTML/CSS/JavaScript using ES Modules). There is **no backend, no database, no build step, and no package manager / dependencies** to install. State is persisted in the browser's `localStorage` (key `genshin-builder-roster`).

### Running the app (dev)
Serve the `genshin-builder/` directory over HTTP and open it in a browser. ES Modules do not load reliably over `file://`, so a static server is required:

```bash
cd genshin-builder
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

Non-obvious gotchas:
- The README references `python` and `https://localhost:8080`. On this VM only `python3` exists (there is no `python` alias), and `http.server` serves plain **HTTP**, so use `python3` and `http://` (not `https://`).
- Serve from **inside** `genshin-builder/` (its `index.html` references `js/` and `css/` relatively).
- Any static file server works (e.g. `npx serve`); the port is arbitrary.

### Lint / test / build
There are **no** lint, test, or build commands — the project has no tooling or config for them. "Building/running" the app just means serving the static files as above.
