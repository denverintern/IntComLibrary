#!/usr/bin/env python3
r"""
PR Editorial Check & Auto-Labeler for the Internationalist Communist Library.

Evaluates modified `_texts/*.md` files in a Pull Request against the editorial checklist:
1. PDF present and embeds (sets `has-pdf` label if PDF present)
2. `source_url` filled (sets `empty-source` label if missing)
3. Slug is `lang-slug` (matches filename and `^[a-z]{2}-[a-z0-9\-]+$`)
4. No body clobber (compares against base branch if file existed previously)
5. `section_id` matches canonical slugs in `_data/taxonomy.json`
6. `language` is one of the allowed codes in `_data/locales.yml`

Outputs computed labels (`ingest`, `needs-review`, `has-pdf`, `empty-source`) and a
Markdown review table for GitHub Actions PR comments / step summaries.
"""

import json
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTS_DIR = os.path.join(REPO_ROOT, "_texts")
UPLOADS_DIR = os.path.join(REPO_ROOT, "assets", "uploads")
TAXONOMY_PATH = os.path.join(REPO_ROOT, "_data", "taxonomy.json")

ALLOWED_LANGS = {
    "en", "es", "pt", "it", "fr", "de", "nl", "ru",
    "zh", "ja", "ko", "ar", "hi", "bn", "id", "tr", "pl", "el"
}


def load_allowed_sections():
    if not os.path.exists(TAXONOMY_PATH):
        return {
            "critique-political-economy",
            "party-state-revolution",
            "historical-materialism",
            "history-communist-left",
        }
    with open(TAXONOMY_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    return {s.get("slug") or s.get("id") for s in data.get("sections", [])}


def parse_md(content):
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            fm_raw = parts[1]
            body = parts[2].strip()
            fm = {}
            for line in fm_raw.splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    fm[k.strip()] = v.strip().strip("\"'")
            return fm, body
    return {}, content.strip()


def get_base_file_content(filepath, base_ref="origin/main"):
    rel_path = os.path.relpath(filepath, REPO_ROOT)
    try:
        res = subprocess.run(
            ["git", "show", f"{base_ref}:{rel_path}"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return res.stdout
    except Exception:
        return None


def main():
    files = [f for f in sys.argv[1:] if f.endswith(".md") and "_texts/" in f]
    head_ref = os.environ.get("GITHUB_HEAD_REF", "")
    base_ref = os.environ.get("GITHUB_BASE_REF", "main")
    base_git_ref = f"origin/{base_ref}" if base_ref else "origin/main"

    allowed_sections = load_allowed_sections()

    labels_to_add = set()
    labels_to_remove = set()

    if head_ref.startswith("ingest/") or files:
        labels_to_add.add("ingest")
        labels_to_add.add("needs-review")

    any_has_pdf = False
    any_empty_source = False
    hard_errors = []
    rows_md = []

    for rel_file in files:
        abs_path = os.path.join(REPO_ROOT, rel_file)
        if not os.path.exists(abs_path):
            continue

        with open(abs_path, "r", encoding="utf-8") as f:
            content = f.read()

        fm, body = parse_md(content)
        filename_stem = os.path.splitext(os.path.basename(rel_file))[0]

        doc_id = fm.get("id", filename_stem)
        title = fm.get("title", "")
        lang = fm.get("language", "")
        section_id = fm.get("section_id", "")
        pdf_val = fm.get("pdf", "")
        source_url = fm.get("source_url", "")
        status = fm.get("status", "published")

        # 1. Check PDF presence
        pdf_ok = False
        if pdf_val:
            if "://" in pdf_val:
                pdf_ok = True
                any_has_pdf = True
            else:
                pdf_file_path = os.path.join(UPLOADS_DIR, pdf_val)
                if os.path.exists(pdf_file_path):
                    pdf_ok = True
                    any_has_pdf = True
                else:
                    hard_errors.append(
                        f"`{rel_file}`: declares `pdf: {pdf_val}` but `assets/uploads/{pdf_val}` is missing."
                    )

        # 2. Check source_url
        has_source = bool(source_url.strip())
        if not has_source:
            any_empty_source = True

        # 3. Check slug is lang-slug
        slug_ok = (
            bool(re.match(r"^[a-z]{2}-[a-z0-9\-]+$", filename_stem))
            and doc_id == filename_stem
            and filename_stem.startswith(f"{lang}-")
        )
        if not slug_ok:
            hard_errors.append(
                f"`{rel_file}`: slug/id `{doc_id}` must match filename `{filename_stem}` and start with `{lang}-`."
            )

        # 4. Check no body clobber against base branch
        base_content = get_base_file_content(abs_path, base_git_ref)
        clobber_ok = True
        if base_content:
            _, base_body = parse_md(base_content)
            if len(base_body) > 100 and len(body) < len(base_body) * 0.5:
                clobber_ok = False
                hard_errors.append(
                    f"`{rel_file}`: potential body clobber detected (previous body {len(base_body)} chars reduced to {len(body)} chars)."
                )

        # 5. Check section_id matches taxonomy
        section_ok = section_id in allowed_sections
        if not section_ok:
            hard_errors.append(
                f"`{rel_file}`: invalid `section_id: {section_id}` (allowed: {', '.join(sorted(allowed_sections))})."
            )

        # 6. Check language in allowed codes
        lang_ok = lang in ALLOWED_LANGS
        if not lang_ok:
            hard_errors.append(
                f"`{rel_file}`: invalid `language: {lang}` (allowed: {', '.join(sorted(ALLOWED_LANGS))})."
            )

        preview_path = f"/texts/{filename_stem}.html"
        rows_md.append(
            f"| `{filename_stem}` | {title or '—'} | `{lang}` | `{section_id}` | "
            f"{'✅ `' + pdf_val + '`' if pdf_ok else '—'} | "
            f"{'✅ [Link](' + source_url + ')' if has_source else '⚠️ `empty-source`'} | "
            f"`{status}` | {'✅' if (slug_ok and section_ok and lang_ok and clobber_ok) else '❌'} | "
            f"`{preview_path}` |"
        )

    if any_has_pdf:
        labels_to_add.add("has-pdf")
    else:
        labels_to_remove.add("has-pdf")

    if any_empty_source:
        labels_to_add.add("empty-source")
    else:
        labels_to_remove.add("empty-source")

    summary_lines = [
        "### 📋 Automated Editorial Desk Check",
        "",
        f"**Computed PR Labels:** {', '.join(f'`{l}`' for l in sorted(labels_to_add)) or 'None'}",
        "",
    ]

    if rows_md:
        summary_lines.extend([
            "| ID (`lang-slug`) | Title | Lang | Section | PDF | Source URL | Status | Valid | Work Path |",
            "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
            *rows_md,
            "",
        ])

    if hard_errors:
        summary_lines.append("#### ❌ Validation Errors")
        for err in hard_errors:
            summary_lines.append(f"- {err}")
        summary_lines.append("")
    else:
        summary_lines.append("#### ✅ All automated schema & non-clobber checks passed.")
        summary_lines.append("")

    summary_md = "\n".join(summary_lines)
    print(summary_md)

    summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a", encoding="utf-8") as f:
            f.write(summary_md + "\n")

    with open("/tmp/pr_editorial_summary.md", "w", encoding="utf-8") as f:
        f.write(summary_md)

    gh_output = os.environ.get("GITHUB_OUTPUT")
    if gh_output:
        with open(gh_output, "a", encoding="utf-8") as f:
            f.write(f"labels_add={','.join(sorted(labels_to_add))}\n")
            f.write(f"labels_remove={','.join(sorted(labels_to_remove))}\n")
            f.write(f"has_errors={'true' if hard_errors else 'false'}\n")

    if hard_errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
