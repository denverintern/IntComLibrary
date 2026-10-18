#!/usr/bin/env python3
"""
Normalize all `_texts/*.md` records to conform strictly to `_data/schema.yml`.
- Repairs any leading keys accidentally placed before the opening `---`.
- Enforces canonical `id` ({lang}-{slug}) matching the filename stem.
- Normalizes `pdf` references to `{id}.pdf` in `assets/uploads/{id}.pdf`.
- Removes redundant hardcoded `section_title` and `section_url` from frontmatter.
- Ensures `status` (`draft` or `published`) is explicitly set on every record.
- Preserves the Markdown body verbatim.
"""

import glob
import os
import re

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTS_DIR = os.path.join(REPO_ROOT, "_texts")


def parse_record(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        raw = f.read()

    pre_lines = []
    while not raw.startswith("---") and "\n" in raw:
        first_line, rest = raw.split("\n", 1)
        if ":" in first_line:
            pre_lines.append(first_line)
            raw = rest
        else:
            break

    fm = {}
    body = ""
    if raw.startswith("---"):
        parts = raw.split("---", 2)
        if len(parts) >= 3:
            fm_lines = pre_lines + parts[1].splitlines()
            body = parts[2].strip()
            for line in fm_lines:
                line = line.strip()
                if not line or line.startswith("#") or ":" not in line:
                    continue
                k, v = line.split(":", 1)
                k = k.strip()
                v = v.strip()
                if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
                    v = v[1:-1].replace('\\"', '"')
                fm[k] = v
    return fm, body


def quote_yaml(val):
    escaped = str(val).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def format_record(doc_id, fm, body):
    lang = fm.get("language", doc_id.split("-", 1)[0])
    title = fm.get("title", "")
    author = fm.get("author", "")
    year = fm.get("year", "")
    section_id = fm.get("section_id", "")
    pdf = fm.get("pdf", "")
    if pdf:
        # Normalize local PDF filename to {id}.pdf
        if "://" not in pdf:
            pdf = f"{doc_id}.pdf"
    source_url = fm.get("source_url", "")
    edition = fm.get("edition", "")
    translators = fm.get("translators", "")
    category = fm.get("category", "")
    subcategory = fm.get("subcategory", "")
    description = fm.get("description", "")
    status = fm.get("status", "published").lower()
    if status not in ("draft", "published"):
        status = "published"

    lines = [
        "---",
        "layout: text",
        f"id: {quote_yaml(doc_id)}",
        f"title: {quote_yaml(title)}",
        f"author: {quote_yaml(author)}",
        f"year: {int(year) if str(year).isdigit() else year}",
        f"language: {quote_yaml(lang)}",
        f"section_id: {quote_yaml(section_id)}",
    ]

    if pdf:
        lines.append(f"pdf: {quote_yaml(pdf)}")
    if source_url:
        lines.append(f"source_url: {quote_yaml(source_url)}")
    if edition:
        lines.append(f"edition: {quote_yaml(edition)}")
    if translators:
        lines.append(f"translators: {quote_yaml(translators)}")
    if category:
        lines.append(f"category: {quote_yaml(category)}")
    if subcategory:
        lines.append(f"subcategory: {quote_yaml(subcategory)}")
    if description:
        lines.append(f"description: {quote_yaml(description)}")

    lines.append(f"status: {status}")
    lines.append("---")
    lines.append("")
    if body:
        lines.append(body)
        lines.append("")

    return "\n".join(lines)


def main():
    files = sorted(glob.glob(os.path.join(TEXTS_DIR, "*.md")))
    for path in files:
        doc_id = os.path.splitext(os.path.basename(path))[0]
        fm, body = parse_record(path)
        normalized = format_record(doc_id, fm, body)
        with open(path, "w", encoding="utf-8") as f:
            f.write(normalized)
        print(f"[+] Normalized: {doc_id}")


if __name__ == "__main__":
    main()
