# Card format

Every folder in here that directly contains a `flashcard.md` is one card. Every
other folder is a category, and categories can nest as deep as you like:

```
flashcards/
├── biology/
│   └── cells/
│       └── mitosis/          ← a card
│           ├── flashcard.md
│           └── phases.png
└── capital_of_peru/          ← a card with no category ("Uncategorized")
    └── flashcard.md
```

- **A card's identity is its folder path** (`biology/cells/mitosis`). Renaming or
  moving the folder makes it a brand-new card, and its review history is lost.
- **Any change** to `flashcard.md` or to a file in the card folder resets the card
  to new.
- Everything inside a card folder belongs to that card, including subfolders. A
  `flashcard.md` nested inside another card is ignored.
- Folder names are shown prettified: `organic_chemistry` → "Organic Chemistry".
- This README isn't inside a card folder, so the app ignores it.

## `flashcard.md`

```markdown
---
title: Mitosis phases
tags: [biology, cells]
---
## Front
![Cell diagram](phases.png)
Name the four phases of mitosis.

## Back
1. Prophase
2. Metaphase
3. Anaphase
4. Telophase
```

- **Frontmatter is optional.** `title` is display-only and may repeat across
  cards; without one, the folder name is used. `tags` can be `[a, b]` or a list of
  `- a` lines.
- **`## Front` and `## Back` are required** and can't be empty. Anything before
  `## Front` is ignored. Other headings are allowed inside a section.
- **Images**: reference files in the card folder with relative paths, e.g.
  `![alt](phases.png)` or `![alt](img/detail.png)`. Each image is shown full width
  on its own line.
- **Supported markdown**: paragraphs, `#` headings, bullet and numbered lists
  (indent 2 spaces to nest), **bold**, *italic*, `inline code`, links,
  `> quotes`, fenced code blocks and `---` rules. Math and syntax highlighting
  aren't supported.

Cards that can't be parsed are skipped and listed in the app under
**Settings → Sync issues**, along with any missing images.
