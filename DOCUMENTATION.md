# Internationalist Communist Library (IntComLibrary)
## Comprehensive Project Summary & Development Overview

---

### 1. Executive Summary & Archival Mission
The **Internationalist Communist Library** is a dedicated digital repository and educational archive preserving the foundational texts, theoretical theses, and historical manifestos of the internationalist communist tradition—specifically emphasizing the invariant doctrines of scientific socialism, the Communist Left (Italian and Dutch-German left traditions), and revolutionary Marxism.

The platform provides a homogeneous, distraction-free environment for militants, scholars, and working-class students globally. It operates entirely as an open-source static archive that is resilient, offline-capable, and optimized for speed and longevity.

---

### 2. Core Architecture & Technical Foundation

* **Static Site Engine**: Powered by **Jekyll** with custom Liquid templating, compiling in under **0.2 seconds** for ultra-fast deployments and zero server maintenance overhead.
* **Storage & Directory Structure**:
  - `_texts/`: 37+ markdown documents containing theoretical texts, historical overviews, and frontmatter metadata (`section_id`, `category`, `subcategory`, `pdf`, `description`).
  - `_data/taxonomy.json`: Canonical definition of the library's four primary thematic sections, sub-themes, and localized naming conventions.
  - `_includes/`: Reusable components including the responsive header, localized language navigation bar (`nav.html`), universal catalog reader (`archive.html`), and homogeneous stylesheet (`style.css`).
  - `_layouts/`: Default site shell (`default.html`), individual text reader (`text.html`), and thematic section overviews (`section.html`).
  - `assets/uploads/`: High-resolution PDFs and downloadable facsimile prints.
  - `manage/`: The in-browser Editorial & Archives Management Desk (`manage/index.html`).
  - `scripts/`: Automated synchronization engines (`sync_gdrive.py`).

---

### 3. Internationalization Across 18 World Languages
A core tenet of internationalism is universal accessibility. The library provides localized archive homepages, navigation, and translated search placeholders across 18 major world languages:

| Language | Directory | Script / Direction |
| :--- | :--- | :--- |
| **English** | `/` (root) | Latin (LTR) |
| **Español** | `/es/` | Latin (LTR) |
| **Português** | `/pt/` | Latin (LTR) |
| **Français** | `/fr/` | Latin (LTR) |
| **Italiano** | `/it/` | Latin (LTR) |
| **Deutsch** | `/de/` | Latin (LTR) |
| **Nederlands** | `/nl/` | Latin (LTR) |
| **Русский** | `/ru/` | Cyrillic (LTR) |
| **中文 (Chinese)** | `/zh/` | Hanzi (LTR) |
| **日本語 (Japanese)** | `/ja/` | Kanji/Kana (LTR) |
| **한국어 (Korean)** | `/ko/` | Hangul (LTR) |
| **العربية (Arabic)** | `/ar/` | Arabic (RTL with native layout inversion) |
| **हिन्दी (Hindi)** | `/hi/` | Devanagari (LTR) |
| **বাংলা (Bengali)** | `/bn/` | Bengali (LTR) |
| **Bahasa Indonesia** | `/id/` | Latin (LTR) |
| **Türkçe** | `/tr/` | Latin (LTR) |
| **Polski** | `/pl/` | Latin (LTR) |
| **Ελληνικά (Greek)** | `/el/` | Greek (LTR) |

---

### 4. Thematic Taxonomy & Curated Collections
All works in the archive are organized into four canonical thematic sections, indexed using classical Roman numerals:

1. **Section I: Critique of Political Economy**
   * *Categories*: Value, Surplus Value & Capital; Imperialism & Monopoly Capitalism.
   * *Subcategories*: Labour Theory of Value, Wages & Exploitation, Capital Accumulation, Finance Capital, Inter-Imperialist War, Global Cartels.
   * *Sample Works*: Marx's *Capital* (Volume 1), *Grundrisse*, *Wage Labour and Capital*, *Value, Price and Profit*; Lenin's *Imperialism, the Highest Stage of Capitalism*.
2. **Section II: Party, State & Revolution**
   * *Categories*: State & Proletarian Dictatorship; Vanguard Party & Organic Centralism.
   * *Subcategories*: Smashing the Bourgeois State, Withering Away of the State, Commune & Soviet State, Party & Class, Critique of the Democratic Principle.
   * *Sample Works*: Lenin's *The State and Revolution*; Bordiga's *Party and Class*, *The Democratic Principle*, *Theses on the Role of the Communist Party*.
3. **Section III: Historical Materialism & Method**
   * *Categories*: Marxist Epistemology & Dialectics.
   * *Subcategories*: Materialist Method, Ideology Critique, Historical Determinism.
4. **Section IV: Tactics & History of the Communist Left**
   * *Categories*: Struggle Against Degeneration & Opportunism.
   * *Subcategories*: Lyon Theses (1926), Critique of Popular Fronts, Programmatic Invariance.
   * *Sample Works*: *The Lyon Theses* (PCd'I 1926).

---

### 5. Visual Design Evolution (`intcp.org` Archival Standard)
The interface was systematically transformed to adhere to the strict, dignified aesthetic of classical communist party publications (such as `intcp.org` and *Il Programma Comunista*):

* **Disciplined Typographic Hierarchy**:
  - Masthead: Letter-spaced `Cinzel` in deep crimson (`#9e1b1e`).
  - Titles, Headings, and Excerpts: Classical scholarly serif (`Georgia, "Times New Roman", serif`) with natural casing and balanced line heights.
  - Author Attributions: Understated italic serif in warm bronze/gold (`#c99e2b`).
  - Functional Controls & Tables: Crisp neutral system typography.
* **Eradication of "Bubbles" and Emojis**:
  - Replaced rounded `20px` bubble pills with **crisp, rectangular archival tabs** (`border-radius: 2px`) featuring clean borders and subtle active states.
  - Stripped all playful emojis from the sidebar, category tabs, book cards, and control panel.
  - Numbered sidebar thematic sections using Roman numerals (`I.`, `II.`, `III.`, `IV.`).
* **Dual Archival Themes**:
  - **Dark Mode**: Deep charcoal background (`#0d0e12`), dark card slate (`#13161c`), crimson accents (`#9e1b1e`), and ivory text (`#f3f4f6`).
  - **Light Mode**: Warm historical parchment/ivory (`#f7f5ef`), clean white cards (`#ffffff`), dark charcoal text (`#18191c`), and deep crimson borders (`#8b1214`).
  - Smooth theme toggle with zero flash of unstyled content (FOUC) and persistence via `localStorage`.
* **Dynamic Client-Side Interactivity**:
  - **Live Filter Toolbar**: Clicking any thematic category filters the archive instantaneously without page reload.
  - **View Switcher (`⊞ Grid` vs `☰ Catalog Table`)**: Users can toggle between spacious scholarly cards or a high-density tabular catalog view.
  - **Instant Search**: Filters by title, author, category, and text description in real time.

---

### 6. Editorial Governance & Passcode Security Hierarchy
To protect the integrity of the archive while enabling collaborative contribution, the **Editorial & Moderator Desk** ([`/manage/index.html`](file:///Volumes/MLDMacExt/IntComLibrary/manage/index.html)) features a two-tiered authorization architecture:

```
                          ┌────────────────────────────┐
                          │   Authentication Gate      │
                          │   (Passcode Verification)  │
                          └─────────────┬──────────────┘
                                        │
                 ┌──────────────────────┴──────────────────────┐
                 ▼                                             ▼
    [Passcode: lead-admin-1917]                   [Passcode: mod-desk-1921]
    ┌───────────────────────────┐                 ┌───────────────────────────┐
    │    Lead Administrator     │                 │    Editorial Moderator    │
    │      (Full Authority)     │                 │   (Restricted Drafter)    │
    └────────────┬──────────────┘                 └─────────────┬─────────────┘
                 │                                              │
 ┌───────────────┼────────────────┐                             │
 │ • Review & Approve Submissions │                             │
 │ • Direct Publishing (.md)      │                             │
 │ • Edit All 37+ Existing Texts  │                             │
 │ • Modify Sections & Taxonomy   │                             │
 │ • Sheets Sync Configuration    │                             │
 │ • Change Passcodes in UI       │                             │
 └────────────────────────────────┘                             │
                 ▲                                              │
                 │              "Pending Approval"              │
                 └──────────────────────────────────────────────┘
```

#### Permission Breakdown:
1. **Lead Administrator (Master Authority)**:
   - **Default Passcode**: `lead-admin-1917` (configurable in the UI).
   - Access to all six management tabs:
     - **Submissions Queue**: Inspect text submissions sent by moderators, preview full Markdown commentary, and click **Approve & Download**, **Edit Before Approving**, or **Reject**.
     - **Add New Work**: Direct publishing and Markdown export without review.
     - **Edit Existing Work**: Full modification capabilities for all 37+ existing works in the library.
     - **Sections & Taxonomy**: Create new sections, categories, and download updated `taxonomy.json`.
     - **Google Sheets Sync**: Reference column mappings and download CSV ingestion templates.
     - **Passcodes & Security**: Update or reset access passcodes at will.
2. **Editorial Moderator (Restricted Contributor)**:
   - **Default Passcode**: `mod-desk-1921` (configurable by the Lead Administrator).
   - Access restricted **strictly** to the **Add New Work** form.
   - All other tabs (`tab-approvals`, `tab-edit-book`, `tab-taxonomy`, `tab-sheets`, `tab-security`) are completely locked and hidden.
   - **Moderator Safeguard**: When a moderator submits a work, it is **never** published directly to the live site. It is routed into the local **Pending Submissions Queue** (`lib_pending_submissions`), requiring inspection and explicit approval from the Lead Administrator.

---

### 7. Automation Pipeline & Ingestion Engine (`scripts/sync_gdrive.py`)
To allow external contributors to submit works via Google Forms or shared spreadsheets without touching git code:
* The sync script reads from either a **Google Service Account** or a **Public Google Sheet CSV**.
* Automatically detects and maps columns: `Title`, `Author`, `Language`, `Section`, `Category`, `Subcategory`, `Description`, and `Drive_Link`.
* Resolves section names against `_data/taxonomy.json` to assign canonical `section_id` and localized URLs.
* Downloads linked PDF files directly into `assets/uploads/`.
* **Non-Destructive Update**: Preserves rich Markdown study guides and custom commentary written by moderators during metadata refreshes.

---

### 8. Repository & Deployment Status
* **Remote Repository**: `https://github.com/denverintern/IntComLibrary.git`
* **Active Branch**: `main`
* **Compilation Status**: Clean build, 0 warnings, 0 errors, generated in `~0.136 seconds`.
