#!/usr/bin/env python3
"""
Sync Google Drive / Google Form responses to the Internationalist Communist Library.

QUEUE & ASSIGNMENT LEDGER MODE:
- Reads from Google Sheets (or --local-csv for dry-run / testing).
- Processes rows where status is empty, 'new', or 'draft'.
- Supports assignment ledger columns:
    * assignee (who reviews)
    * priority (review priority)
    * notes    (internal moderator notes — NEVER written to public markdown)
    * status   (new | pending | published | draft | error)
- Validates data (slugs, year, lang, taxonomy section_id).
- Skips PDF download if drive_id matches existing frontmatter and file exists.
- Preserves existing markdown body and custom frontmatter (never clobbers body).
- Writes status='pending' (or 'error: ...') back to the sheet.
- Generates PR body with checklist + ledger table and sends Discord / Email notifications
  when a PR opens or when auth/sync errors occur.
"""

import argparse
import csv
import io
import json
import os
import re
import smtplib
import sys
import urllib.request
from email.message import EmailMessage

try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaIoBaseDownload
    GOOGLE_LIBS_AVAILABLE = True
except ImportError:
    GOOGLE_LIBS_AVAILABLE = False

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
TEXTS_DIR = os.path.join(REPO_ROOT, "_texts")
UPLOADS_DIR = os.path.join(REPO_ROOT, "assets", "uploads")
TAXONOMY_PATH = os.path.join(REPO_ROOT, "_data", "taxonomy.json")
PR_TEMPLATE_PATH = os.path.join(REPO_ROOT, ".github", "PULL_REQUEST_TEMPLATE.md")

MANIFEST_PATH = "/tmp/ingest_manifest.json"
PR_BODY_PATH = "/tmp/ingest_pr_body.md"

VALID_LANGS = {
    "en", "es", "pt", "it", "fr", "de", "nl", "ru",
    "zh", "ja", "ko", "ar", "hi", "bn", "id", "tr", "pl", "el"
}


def load_taxonomy():
    if not os.path.exists(TAXONOMY_PATH):
        return {}
    with open(TAXONOMY_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    sections = {}
    for s in data.get("sections", []):
        slug = s.get("slug") or s.get("id")
        if slug:
            sections[slug] = s.get("title", {})
    return sections


def slugify(text):
    text = text.lower()
    text = re.sub(r"[^a-z0-9\-]", "-", text)
    text = re.sub(r"-+", "-", text).strip("-")
    return text


def extract_drive_id(url):
    match = re.search(r"/file/d/([^/]+)", url)
    if match:
        return match.group(1)
    match = re.search(r"id=([^&]+)", url)
    if match:
        return match.group(1)
    return None


def parse_md(filepath):
    if not os.path.exists(filepath):
        return {}, ""
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
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


def col_num_to_letter(n):
    string = ""
    n += 1
    while n > 0:
        n, remainder = divmod(n - 1, 26)
        string = chr(65 + remainder) + string
    return string


def send_notification(subject, message_md, discord_embeds=None):
    """Send notification to Discord webhook and/or SMTP email if configured."""
    webhook_url = os.environ.get("DISCORD_WEBHOOK_URL", "").strip()
    smtp_host = os.environ.get("SMTP_HOST", "").strip()
    notify_email = os.environ.get("NOTIFY_EMAIL", "").strip()

    sent_any = False

    if webhook_url:
        payload = {"content": message_md}
        if discord_embeds:
            payload["embeds"] = discord_embeds
        req = urllib.request.Request(
            webhook_url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "User-Agent": "IntComLibrary-IngestBot/1.0",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                print(f"[+] Discord notification sent (HTTP {resp.status}).")
                sent_any = True
        except Exception as e:
            print(f"[!] Failed to send Discord webhook notification: {e}")

    if smtp_host and notify_email:
        smtp_port = int(os.environ.get("SMTP_PORT", "587"))
        smtp_user = os.environ.get("SMTP_USER", "").strip()
        smtp_pass = os.environ.get("SMTP_PASS", "").strip()
        smtp_from = os.environ.get("SMTP_FROM", smtp_user or "noreply@intcomlibrary.org")
        try:
            msg = EmailMessage()
            msg["Subject"] = subject
            msg["From"] = smtp_from
            msg["To"] = notify_email
            msg.set_content(message_md)
            with smtplib.SMTP(smtp_host, smtp_port, timeout=15) as server:
                server.starttls()
                if smtp_user and smtp_pass:
                    server.login(smtp_user, smtp_pass)
                server.send_message(msg)
            print(f"[+] Email notification sent to {notify_email}.")
            sent_any = True
        except Exception as e:
            print(f"[!] Failed to send email notification: {e}")

    if not sent_any:
        print(f"[*] Notification payload prepared (no DISCORD_WEBHOOK_URL or SMTP_HOST set):\n{subject}\n{message_md}")


def notify_pr_opened(pr_url):
    """Send a Discord or email ping when an ingest PR opens/updates, with link and title(s)."""
    if not os.path.exists(MANIFEST_PATH):
        msg = f"📥 **Ingest PR Ready for Review**\n🔗 {pr_url}"
        send_notification("📥 [ICL] Ingest PR Ready for Review", msg)
        return

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    items = manifest.get("items", [])
    labels = manifest.get("labels", [])
    pr_title = manifest.get("pr_title", "📥 Ingest new texts from Google Drive")

    lines = [
        f"**{pr_title}**",
        f"🔗 **PR Link:** {pr_url}",
        f"🏷️ **Labels:** {', '.join(f'`{l}`' for l in labels)}",
        "",
        "**Works in Queue:**",
    ]
    for item in items:
        assignee_str = f" — **Assignee:** `{item['assignee']}`" if item.get("assignee") else ""
        prio_str = f" (`{item['priority']}`)" if item.get("priority") else ""
        lines.append(
            f"- **{item['title']}** by {item['author']} (`{item['id']}`, `{item['status']}`){assignee_str}{prio_str}"
        )

    message_md = "\n".join(lines)
    send_notification(f"[ICL Editorial Queue] {pr_title}", message_md)


def write_github_outputs(outputs_dict):
    gh_output = os.environ.get("GITHUB_OUTPUT")
    if gh_output:
        with open(gh_output, "a", encoding="utf-8") as f:
            for k, v in outputs_dict.items():
                f.write(f"{k}={v}\n")


def main():
    parser = argparse.ArgumentParser(description="ICL Google Sheet & Drive Ingest Pipeline")
    parser.add_argument("--dry-run", action="store_true", help="Validate and print rows without writing files or updating Sheet")
    parser.add_argument("--local-csv", type=str, default="", help="Read rows from a local CSV file instead of Google Sheets API")
    parser.add_argument("--as-draft", action="store_true", help="Write ingested markdown files with status: draft")
    parser.add_argument("--notify-pr", type=str, default="", help="Send Discord/email notification for opened PR URL")
    parser.add_argument("--notify-error", type=str, default="", help="Send loud Discord/email alert on workflow failure")
    args = parser.parse_args()

    if args.notify_pr:
        notify_pr_opened(args.notify_pr)
        return

    if args.notify_error:
        send_notification(
            "🚨 [ICL Ingest Pipeline Failure]",
            f"🚨 **ICL Ingest Workflow Failed**\nReason: {args.notify_error}",
        )
        return

    dry_run = args.dry_run or os.environ.get("DRY_RUN", "false").lower() == "true"
    local_csv = args.local_csv or os.environ.get("GDRIVE_LOCAL_CSV", "").strip()
    force_draft = args.as_draft or os.environ.get("INGEST_AS_DRAFT", "false").lower() == "true"

    if dry_run:
        print("--- DRY RUN MODE: No files or sheets will be modified ---")
    print("=" * 60)
    print("  ICL Ingest Pipeline (PR Editorial Queue)")
    print("=" * 60)

    taxonomy_sections = load_taxonomy()
    allowed_sections = set(taxonomy_sections.keys()) or {
        "critique-political-economy",
        "party-state-revolution",
        "historical-materialism",
        "history-communist-left",
    }

    sheets_service = None
    drive_service = None
    first_sheet_title = "Sheet1"
    sheet_id = os.environ.get("GDRIVE_SHEET_ID", "").strip()

    if local_csv:
        if not os.path.exists(local_csv):
            print(f"[!] Local CSV not found: {local_csv}")
            sys.exit(1)
        with open(local_csv, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            values = list(reader)
    else:
        creds_env = os.environ.get("GDRIVE_CREDENTIALS", "").strip()
        if not creds_env or not sheet_id:
            err = "Missing GDRIVE_CREDENTIALS or GDRIVE_SHEET_ID"
            print(f"[!] {err}")
            send_notification("🚨 [ICL Ingest Auth Error]", f"🚨 **Ingest Error:** {err}")
            sys.exit(1)

        if not GOOGLE_LIBS_AVAILABLE:
            err = "google-api-python-client not installed"
            print(f"[!] {err}")
            sys.exit(1)

        scopes = [
            "https://www.googleapis.com/auth/spreadsheets",
            "https://www.googleapis.com/auth/drive.readonly",
        ]

        try:
            if os.path.exists(creds_env):
                creds = service_account.Credentials.from_service_account_file(creds_env, scopes=scopes)
            else:
                creds = service_account.Credentials.from_service_account_info(json.loads(creds_env), scopes=scopes)

            sheets_service = build("sheets", "v4", credentials=creds)
            drive_service = build("drive", "v3", credentials=creds)

            sheet_meta = sheets_service.spreadsheets().get(spreadsheetId=sheet_id).execute()
            first_sheet_title = sheet_meta["sheets"][0]["properties"]["title"]

            result = (
                sheets_service.spreadsheets()
                .values()
                .get(spreadsheetId=sheet_id, range=first_sheet_title)
                .execute()
            )
            values = result.get("values", [])
        except Exception as e:
            err = f"Google Sheets / Drive authentication or read failed: {e}"
            print(f"[!] {err}")
            send_notification("🚨 [ICL Ingest Auth/Sheet Error]", f"🚨 **Ingest Failure:** {err}")
            sys.exit(1)

    if not values or len(values) < 2:
        print("[*] No rows found.")
        write_github_outputs({"ingested_count": "0"})
        sys.exit(0)

    headers = [h.strip().lower() for h in values[0]]
    col_idx = {h: i for i, h in enumerate(headers)}

    for req in ["title", "author", "year", "language", "status"]:
        if req not in col_idx:
            err = f"Missing required column in sheet: {req}"
            print(f"[!] {err}")
            send_notification("🚨 [ICL Ingest Schema Error]", f"🚨 **Schema Error:** {err}")
            sys.exit(1)

    status_col_index = col_idx["status"]
    status_col_letter = col_num_to_letter(status_col_index)

    updates = []
    ingested_items = []
    any_has_pdf = False
    any_empty_source = False

    os.makedirs(TEXTS_DIR, exist_ok=True)
    os.makedirs(UPLOADS_DIR, exist_ok=True)

    for row_num, row in enumerate(values[1:], start=2):
        row_dict = {
            h: (row[col_idx[h]] if col_idx[h] < len(row) else "").strip()
            for h in headers
        }

        raw_status = row_dict.get("status", "").strip().lower()
        if raw_status in ["published", "pending"] or raw_status.startswith("error"):
            continue

        title = row_dict.get("title", "")
        author = row_dict.get("author", "")
        year = row_dict.get("year", "")
        language = row_dict.get("language", "").lower()
        section_id = row_dict.get("section_id", "")
        pdf_link = row_dict.get("pdf_link", "")
        if pdf_link.lower().strip() == "n/a":
            pdf_link = ""
        if not pdf_link:
            for k, v in row_dict.items():
                if ("file" in k or "upload" in k or "submission" in k) and "drive.google.com" in v:
                    pdf_link = v
                    break

        source_url = row_dict.get("source_url", "")
        desc = row_dict.get("description", "")
        custom_id = row_dict.get("id", "")
        category = row_dict.get("category", "")
        subcategory = row_dict.get("subcategory", "")

        # Assignment ledger fields (internal operations only — never written to public markdown body)
        assignee = row_dict.get("assignee", "")
        priority = row_dict.get("priority", "")
        notes = row_dict.get("notes", "")

        errors = []
        if language not in VALID_LANGS:
            errors.append(f"Invalid language: {language}")
        if section_id and section_id not in allowed_sections:
            errors.append(f"Invalid section_id: {section_id}")
        elif not section_id:
            errors.append("Missing section_id")
        if not re.match(r"^\d{4}$", year):
            errors.append(f"Invalid year: {year}")
        if not title or not author:
            errors.append("Missing title or author")

        base_slug = slugify(title)
        doc_id = custom_id if custom_id else f"{language}-{base_slug}"
        if not doc_id.startswith(f"{language}-"):
            doc_id = f"{language}-{doc_id}"
        if not re.match(r"^[a-z]{2}-[a-z0-9\-]+$", doc_id):
            errors.append(f"Invalid slug: {doc_id}")

        if errors:
            err_msg = "error: " + " | ".join(errors)
            updates.append({
                "range": f"{first_sheet_title}!{status_col_letter}{row_num}",
                "values": [[err_msg]],
                "row_num": row_num,
                "status": err_msg,
            })
            print(f"[!] Row {row_num} failed validation: {err_msg}")
            continue

        md_filename = f"{doc_id}.md"
        pdf_filename = f"{doc_id}.pdf"
        md_path = os.path.join(TEXTS_DIR, md_filename)
        pdf_path = os.path.join(UPLOADS_DIR, pdf_filename)

        existing_fm, existing_body = parse_md(md_path)

        drive_id = extract_drive_id(pdf_link) if pdf_link else None
        has_pdf = False

        if drive_id:
            existing_drive_id = existing_fm.get("drive_id", "")
            pdf_exists = os.path.exists(pdf_path)

            if not pdf_exists or drive_id != existing_drive_id:
                print(f"[+] Downloading PDF for: '{title}'...")
                if not dry_run and drive_service is not None:
                    try:
                        request = drive_service.files().get_media(fileId=drive_id)
                        fh = io.FileIO(pdf_path, "wb")
                        downloader = MediaIoBaseDownload(fh, request)
                        done = False
                        while done is False:
                            _, done = downloader.next_chunk()
                        has_pdf = True
                    except Exception as e:
                        errors.append(f"PDF download failed: {e}")
                else:
                    print("    (DRY RUN / Local mode: skipping Drive download)")
                    has_pdf = True
            else:
                has_pdf = True
        elif os.path.exists(pdf_path):
            has_pdf = True

        if errors:
            err_msg = "error: " + " | ".join(errors)
            updates.append({
                "range": f"{first_sheet_title}!{status_col_letter}{row_num}",
                "values": [[err_msg]],
                "row_num": row_num,
                "status": err_msg,
            })
            print(f"[!] Row {row_num} failed PDF step: {err_msg}")
            continue

        # Resolve section_title from taxonomy
        sec_titles = taxonomy_sections.get(section_id, {})
        section_title = (
            existing_fm.get("section_title")
            or sec_titles.get(language)
            or sec_titles.get("en")
            or ""
        )

        # Frontmatter generation (notes & assignee are strictly excluded from public markdown!)
        safe_title = title.replace('"', '\\"')
        safe_author = author.replace('"', '\\"')
        safe_desc = desc.replace('"', '\\"')
        safe_cat = (category or existing_fm.get("category", "")).replace('"', '\\"')
        safe_subcat = (subcategory or existing_fm.get("subcategory", "")).replace('"', '\\"')

        final_source_url = source_url if source_url else existing_fm.get("source_url", "")
        final_body = existing_body if existing_body else safe_desc

        target_fm_status = "draft" if (force_draft or raw_status == "draft") else "pending"

        fm_lines = [
            "---",
            "layout: text",
            f'id: "{doc_id}"',
            f'title: "{safe_title}"',
            f'author: "{safe_author}"',
            f"year: {year}",
            f'language: "{language}"',
            f'section_id: "{section_id}"',
        ]

        if section_title:
            fm_lines.append(f'section_title: "{section_title.replace(chr(34), chr(92) + chr(34))}"')
        if safe_cat:
            fm_lines.append(f'category: "{safe_cat}"')
        if safe_subcat:
            fm_lines.append(f'subcategory: "{safe_subcat}"')
        if safe_desc:
            fm_lines.append(f'description: "{safe_desc}"')
        if has_pdf:
            fm_lines.append(f'pdf: "{pdf_filename}"')
        if final_source_url:
            fm_lines.append(f'source_url: "{final_source_url}"')
        if drive_id:
            fm_lines.append(f'drive_id: "{drive_id}"')

        fm_lines.append(f"status: {target_fm_status}")
        fm_lines.append("---")
        fm_lines.append("")
        fm_lines.append(final_body)

        fm = "\n".join(fm_lines) + "\n"

        if not dry_run:
            with open(md_path, "w", encoding="utf-8") as f:
                f.write(fm)

        if has_pdf:
            any_has_pdf = True
        if not final_source_url.strip():
            any_empty_source = True

        ingested_items.append({
            "id": doc_id,
            "title": title,
            "author": author,
            "year": year,
            "language": language,
            "section_id": section_id,
            "has_pdf": has_pdf,
            "source_url": final_source_url,
            "status": target_fm_status,
            "assignee": assignee,
            "priority": priority,
            "notes": notes,
            "row_num": row_num,
        })

        print(
            f"[+] Processed{' (DRY RUN)' if dry_run else ''}: {doc_id} "
            f"[status={target_fm_status}, assignee={assignee or 'unassigned'}, priority={priority or 'normal'}]"
        )
        updates.append({
            "range": f"{first_sheet_title}!{status_col_letter}{row_num}",
            "values": [["pending"]],
            "row_num": row_num,
            "status": "pending",
        })

    # Compute PR labels according to editorial desk rules
    pr_labels = ["ingest", "needs-review"]
    if any_has_pdf:
        pr_labels.append("has-pdf")
    if any_empty_source:
        pr_labels.append("empty-source")

    if len(ingested_items) == 1:
        pr_title = f"📥 Ingest: {ingested_items[0]['title']} ({ingested_items[0]['id']})"
    elif len(ingested_items) > 1:
        pr_title = f"📥 Ingest {len(ingested_items)} texts ({', '.join(i['id'] for i in ingested_items[:3])})"
    else:
        pr_title = "📥 Ingest new texts from Google Drive"

    # Build PR body combining checklist template + assignment ledger table
    template_content = ""
    if os.path.exists(PR_TEMPLATE_PATH):
        with open(PR_TEMPLATE_PATH, "r", encoding="utf-8") as f:
            template_content = f.read().strip()

    ledger_lines = [
        "### 📊 Sheet Assignment Ledger",
        "",
        "| ID (`lang-slug`) | Title | Author | Lang | Section | Status | Assignee | Priority | Internal Notes |",
        "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |",
    ]
    for item in ingested_items:
        ledger_lines.append(
            f"| `{item['id']}` | {item['title']} | {item['author']} | `{item['language']}` | "
            f"`{item['section_id']}` | `{item['status']}` | {item['assignee'] or '—'} | "
            f"{item['priority'] or '—'} | {item['notes'] or '—'} |"
        )
    ledger_lines.append("")

    pr_body = "\n".join(ledger_lines) + "\n" + template_content + "\n"

    manifest = {
        "pr_title": pr_title,
        "labels": pr_labels,
        "dry_run": dry_run,
        "items": ingested_items,
    }
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    with open(PR_BODY_PATH, "w", encoding="utf-8") as f:
        f.write(pr_body)

    write_github_outputs({
        "ingested_count": str(len(ingested_items)),
        "pr_title": pr_title,
        "pr_labels": ",".join(pr_labels),
        "pr_body_path": PR_BODY_PATH,
    })

    if updates:
        if not dry_run:
            if local_csv:
                for u in updates:
                    r_idx = u["row_num"] - 1
                    while len(values[r_idx]) <= status_col_index:
                        values[r_idx].append("")
                    values[r_idx][status_col_index] = u["status"]
                with open(local_csv, "w", encoding="utf-8", newline="") as f:
                    writer = csv.writer(f)
                    writer.writerows(values)
                print(f"[*] Updated {len(updates)} statuses in local CSV: {local_csv}")
            elif sheets_service is not None:
                sheet_data = [{"range": u["range"], "values": u["values"]} for u in updates]
                body = {"valueInputOption": "RAW", "data": sheet_data}
                sheets_service.spreadsheets().values().batchUpdate(
                    spreadsheetId=sheet_id, body=body
                ).execute()
                print(f"[*] Updated {len(updates)} statuses in Google Sheet.")

            if ingested_items:
                repo = os.environ.get("GITHUB_REPOSITORY", "denverintern/IntComLibrary")
                default_pr_link = f"https://github.com/{repo}/pulls?q=is%3Apr+is%3Aopen+head%3Aingest%2Fgdrive-sync"
                notify_pr_opened(os.environ.get("PR_URL", default_pr_link))
        else:
            print(f"[*] DRY RUN: Would have updated {len(updates)} statuses in Sheet.")
    else:
        print("[*] No new rows to process.")


if __name__ == "__main__":
    main()
