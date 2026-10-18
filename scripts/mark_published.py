#!/usr/bin/env python3
"""
Mark merged `_texts/*.md` works as `published` (or `draft` if merged in draft state)
in the Google Sheet assignment ledger.
"""

import argparse
import csv
import json
import os
import re
import sys

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    GOOGLE_LIBS_AVAILABLE = True
except ImportError:
    GOOGLE_LIBS_AVAILABLE = False


def slugify(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9\-]+", "-", text)
    return text.strip("-")


def parse_md_meta(filepath):
    if not os.path.exists(filepath):
        return None, None
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    doc_id = os.path.splitext(os.path.basename(filepath))[0]
    status = "published"
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            for line in parts[1].splitlines():
                if line.startswith("id:"):
                    val = line.split(":", 1)[1].strip().strip("\"'")
                    if val:
                        doc_id = val
                elif line.startswith("status:"):
                    val = line.split(":", 1)[1].strip().strip("\"'").lower()
                    if val:
                        status = val
    if status == "pending":
        status = "published"
    return doc_id, status


def col_num_to_letter(n):
    s = ""
    n += 1
    while n > 0:
        n, remainder = divmod(n - 1, 26)
        s = chr(65 + remainder) + s
    return s


def main():
    parser = argparse.ArgumentParser(description="Mark merged texts as published in Google Sheet")
    parser.add_argument("--local-csv", type=str, default="", help="Update a local CSV ledger instead of Google Sheets")
    parser.add_argument("--dry-run", action="store_true", help="Print status updates without modifying Sheet/CSV")
    parser.add_argument("files", nargs="*", help="List of changed _texts/*.md files")
    args = parser.parse_args()

    if not args.files:
        sys.exit(0)

    status_by_id = {}
    for f in args.files:
        doc_id, st = parse_md_meta(f)
        if doc_id:
            status_by_id[doc_id] = st

    if not status_by_id:
        sys.exit(0)

    local_csv = args.local_csv or os.environ.get("GDRIVE_LOCAL_CSV", "").strip()
    dry_run = args.dry_run or os.environ.get("DRY_RUN", "false").lower() == "true"

    if local_csv:
        if not os.path.exists(local_csv):
            print(f"[!] Local CSV not found: {local_csv}")
            sys.exit(1)
        with open(local_csv, "r", encoding="utf-8") as f:
            values = list(csv.reader(f))
        if len(values) < 2:
            sys.exit(0)
        headers = [h.strip().lower() for h in values[0]]
        if "status" not in headers:
            sys.exit(0)
        status_col = headers.index("status")
        id_col = headers.index("id") if "id" in headers else -1
        title_col = headers.index("title") if "title" in headers else -1
        lang_col = headers.index("language") if "language" in headers else -1

        updated = 0
        for row_num, row in enumerate(values[1:], start=2):
            row_id = row[id_col].strip() if (id_col >= 0 and id_col < len(row)) else ""
            if not row_id and title_col >= 0 and lang_col >= 0:
                title = row[title_col].strip() if title_col < len(row) else ""
                lang = row[lang_col].strip() if lang_col < len(row) else ""
                if title and lang:
                    row_id = f"{lang.lower()}-{slugify(title)}"
            if row_id in status_by_id:
                new_st = status_by_id[row_id]
                while len(row) <= status_col:
                    row.append("")
                row[status_col] = new_st
                updated += 1
                print(f"[+] Row {row_num} ({row_id}) -> status='{new_st}'{' (DRY RUN)' if dry_run else ''}")

        if updated and not dry_run:
            with open(local_csv, "w", encoding="utf-8", newline="") as f:
                writer = csv.writer(f)
                writer.writerows(values)
        return

    creds_env = os.environ.get("GDRIVE_CREDENTIALS", "").strip()
    sheet_id = os.environ.get("GDRIVE_SHEET_ID", "").strip()
    if not creds_env or not sheet_id or not GOOGLE_LIBS_AVAILABLE:
        sys.exit(0)

    scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    if os.path.exists(creds_env):
        creds = service_account.Credentials.from_service_account_file(creds_env, scopes=scopes)
    else:
        creds = service_account.Credentials.from_service_account_info(json.loads(creds_env), scopes=scopes)

    sheets_service = build("sheets", "v4", credentials=creds)
    sheet_meta = sheets_service.spreadsheets().get(spreadsheetId=sheet_id).execute()
    first_sheet_title = sheet_meta["sheets"][0]["properties"]["title"]

    result = (
        sheets_service.spreadsheets()
        .values()
        .get(spreadsheetId=sheet_id, range=first_sheet_title)
        .execute()
    )

    values = result.get("values", [])
    if len(values) < 2:
        sys.exit(0)

    headers = [h.strip().lower() for h in values[0]]
    if "status" not in headers:
        sys.exit(0)

    id_col = headers.index("id") if "id" in headers else -1
    status_col = headers.index("status")
    title_col = headers.index("title") if "title" in headers else -1
    lang_col = headers.index("language") if "language" in headers else -1

    status_letter = col_num_to_letter(status_col)
    updates = []

    for row_num, row in enumerate(values[1:], start=2):
        row_id = row[id_col].strip() if (id_col >= 0 and id_col < len(row)) else ""
        if not row_id and title_col >= 0 and lang_col >= 0:
            title = row[title_col].strip() if title_col < len(row) else ""
            lang = row[lang_col].strip() if lang_col < len(row) else ""
            if title and lang:
                row_id = f"{lang.lower()}-{slugify(title)}"

        if row_id in status_by_id:
            new_st = status_by_id[row_id]
            updates.append({
                "range": f"{first_sheet_title}!{status_letter}{row_num}",
                "values": [[new_st]],
            })
            print(f"[+] Row {row_num} ({row_id}) -> status='{new_st}'{' (DRY RUN)' if dry_run else ''}")

    if updates and not dry_run:
        body = {"valueInputOption": "RAW", "data": updates}
        sheets_service.spreadsheets().values().batchUpdate(spreadsheetId=sheet_id, body=body).execute()
        print(f"[*] Marked {len(updates)} row(s) in Google Sheet.")


if __name__ == "__main__":
    main()
