## Ingest / Editorial Review Summary

- **Standing Branch:** `ingest/gdrive-sync`
- **Google Sheet Ledger:** Verify `assignee`, `priority`, and internal `notes` in the moderation sheet.

---

## Mandatory Moderator Review Checklist

Before approving and merging this Pull Request into `main`, verify every item below:

- [ ] **PDF present and embeds:** Local PDF file exists at `assets/uploads/{lang}-{slug}.pdf` (if applicable) and renders properly in the work page embed viewer.
- [ ] **`source_url` filled:** Canonical external source URL (`source_url`) is populated in frontmatter (or label `empty-source` is acknowledged if PDF-only).
- [ ] **Slug is `lang-slug`:** Filename (`_texts/{lang}-{slug}.md`) and frontmatter `id: {lang}-{slug}` strictly match the `{lang}-{slug}` format (lowercase ASCII alphanumeric and hyphens only).
- [ ] **No body clobber:** Existing transcribed Markdown body in `_texts/{lang}-{slug}.md` was preserved and not overwritten by sheet description sync.
- [ ] **Section ID matches taxonomy:** `section_id` is one of the canonical slugs in `_data/taxonomy.json` (`critique-political-economy`, `party-state-revolution`, `historical-materialism`, `history-communist-left`).
- [ ] **Language is one of the allowed codes:** `language` is a valid code defined in `_data/locales.yml` (`en`, `es`, `pt`, `it`, `fr`, `de`, `nl`, `ru`, `zh`, `ja`, `ko`, `ar`, `hi`, `bn`, `id`, `tr`, `pl`, `el`).
- [ ] **Draft / publication state verified:** Set `status: draft` in frontmatter if the work should merge silently without appearing in public catalogs yet, or `status: pending` / `status: published` to publish immediately on merge.
