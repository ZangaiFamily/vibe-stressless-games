# Vibe Stressless Games — GitHub Pages

Live site: **https://zangaifamily.github.io/vibe-stressless-games/**

## Folder Structure

```
/
├── index.html              # Landing page — lists all games
├── vibe-money/             # Vibe Money (Godot 4.6 web export)
│   ├── index.html
│   ├── index.js
│   ├── index.wasm
│   ├── index.pck
│   └── ...
├── infinite-loop-hex/      # Infinity Loop HEX (Godot 4.6 web export)
│   ├── index.html
│   ├── index.js
│   ├── index.wasm
│   ├── index.pck
│   └── ...
└── README.md               # This file
```

## Game URLs

| Game | URL |
|------|-----|
| Landing Page | [/](https://zangaifamily.github.io/vibe-stressless-games/) |
| Vibe Money | [/vibe-money/](https://zangaifamily.github.io/vibe-stressless-games/vibe-money/) |
| Infinity Loop HEX | [/infinite-loop-hex/](https://zangaifamily.github.io/vibe-stressless-games/infinite-loop-hex/) |

## Adding a New Game

1. Export the Godot project for Web (GL Compatibility renderer)
2. Switch to this branch: `git checkout gh-pages`
3. Create a folder matching the game name: `mkdir <game-name>`
4. Copy the web export files into it
5. Add `coi-serviceworker.js` and inject `<script src="coi-serviceworker.js"></script>` into `<head>` of `index.html`
6. Add a card to the root `index.html`
7. Commit and push
