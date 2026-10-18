# Internationalist Communist Library (`IntComLibrary`)

Static multilingual theoretical archive built with Jekyll and operated via a GitHub Pull Request editorial queue + Google Sheet assignment ledger.

---

## 1. Operations & Editorial Workflow (`ingest/gdrive-sync`)

All moderation and content-team work takes place in the **GitHub Pull Request queue** and the **Google Sheet assignment ledger**—never via client-side passcodes or in-browser file writers.

1. **Form / Sheet Submission (`status: new`):**
   Contributors submit works via the Google Form or add rows directly to the Google Sheet ledger (`assets/library_ingestion_template.csv`).
2. **Automated Sync (`scripts/sync_gdrive.py` & `.github/workflows/sync-gdrive.yml`):**
   - Validates language codes, 4-digit year, `{lang}-{slug}` IDs, and canonical `section_id` slugs against `_data/taxonomy.json`.
   - Downloads new PDFs from Google Drive to `assets/uploads/{id}.pdf` without clobbering existing transcribed Markdown bodies.
   - Commits changes to the single standing branch **`ingest/gdrive-sync`**, opens/updates the Pull Request with the mandatory review checklist and assignment ledger table, sets status to `pending` in the Sheet, and sends a Discord/email ping with the PR link and work title(s).
3. **Automated PR Checks & Labels (`.github/workflows/editorial-pr.yml`):**
   - `scripts/pr_editorial_check.py` inspects modified `_texts/*.md` files and applies canonical labels:
     - `ingest` — Automated or manual text ingestion PR.
     - `needs-review` — Requires 1 moderator approving review before merge.
     - `has-pdf` — Local PDF present in `assets/uploads/` and linked in frontmatter.
     - `empty-source` — Missing external `source_url` in frontmatter.
   - Builds a full Jekyll preview artifact (`pr-preview-<PR_NUMBER>`) and comments the validation summary on the PR.
4. **Draft vs. Immediate Publication (`status: draft`):**
   - Setting `status: draft` in `_texts/{id}.md` frontmatter (or running the sync with `as_draft: true`) allows a work to be built at its direct preview URL (`/texts/{id}.html`) while **excluding it from all public catalog templates and language/section counts**.
   - Once verified, flipping `status: draft` to `status: published` (or merging a `status: pending` PR) publishes the work to the catalog and triggers `.github/workflows/mark-published.yml` (`scripts/mark_published.py`) to set `status = published` in the Google Sheet.

---

## 2. Google Sheet Assignment Ledger Column Map

Template file: [`assets/library_ingestion_template.csv`](assets/library_ingestion_template.csv)

| Column Header | Required | Written to Public Markdown? | Description |
| :--- | :--- | :--- | :--- |
| `id` | Optional | Yes (`id`) | Canonical `{lang}-{slug}` identifier. Auto-generated from `language` + `title` if blank. |
| `title` | **Yes** | Yes (`title`) | Full title of the work. |
| `author` | **Yes** | Yes (`author`) | Author or collective party organ attribution. |
| `year` | **Yes** | Yes (`year`) | 4-digit year (`^\d{4}$`). |
| `language` | **Yes** | Yes (`language`) | Allowed ISO code: `en`, `es`, `pt`, `it`, `fr`, `de`, `nl`, `ru`, `zh`, `ja`, `ko`, `ar`, `hi`, `bn`, `id`, `tr`, `pl`, `el`. |
| `section_id` | **Yes** | Yes (`section_id`) | Canonical taxonomy slug (`critique-political-economy`, `party-state-revolution`, `historical-materialism`, `history-communist-left`). |
| `category` | Optional | Yes (`category`) | Thematic category within the section. |
| `subcategory` | Optional | Yes (`subcategory`) | Specific subcategory focus. |
| `pdf_link` | Optional | Drive ID / `pdf` | Google Drive sharing URL (or `N/A` if uploaded via Form File Upload or external source only). |
| `source_url` | Optional | Yes (`source_url`) | Canonical external HTML/source URL. If empty, PR receives the `empty-source` label. |
| `description` | Optional | Initial body / `description` | Brief summary; **never** clobbers an existing transcribed Markdown body. |
| `assignee` | Ledger | **No** (PR & Ping only) | Content-team reviewer assigned to the row. |
| `priority` | Ledger | **No** (PR & Ping only) | Review priority (`high`, `normal`, `low`). |
| `notes` | Ledger | **No** (Internal only) | Internal editorial notes — strictly excluded from public markdown files. |
| `status` | **Yes** | Yes (`status`) | `new` → `pending` (or `draft`) → `published` | `error: ...` |

---

## 3. Repository Governance & Dry-Run Testing

- **Branch Protection (`main`):** Run `bash scripts/setup_branch_protection.sh` (or trigger `.github/workflows/editorial-pr.yml` via `workflow_dispatch`) to enforce 1 approving review (`required_approving_review_count: 1`) and required status checks on `main`.
- **Dry-Run Mode:** Trigger **Sync from Google Drive** in GitHub Actions with `dry_run: true`, or locally via:
  ```bash
  python3 scripts/sync_gdrive.py --local-csv assets/library_ingestion_template.csv --dry-run
  ```
