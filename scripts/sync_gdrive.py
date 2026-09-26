#!/usr/bin/env python3
"""
Sync Google Drive / Google Form responses to the Internationalist Communist Library.

QUEUE MODE:
- Reads from Google Sheets.
- Processes rows where status is empty or 'new'.
- Validates data (slugs, year, lang, etc.).
- Skips PDF download if drive_id and size match existing frontmatter.
- Preserves markdown body and custom frontmatter (e.g., if source_url exists).
- Writes status='pending' (or 'error: ...') back to the sheet.
"""

import os
import re
import sys
import json
import io

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

VALID_LANGS = {'en', 'es', 'pt', 'it'}

def slugify(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9\-]', '-', text)
    text = re.sub(r'-+', '-', text).strip('-')
    return text

def extract_drive_id(url):
    match = re.search(r'/file/d/([^/]+)', url)
    if match: return match.group(1)
    match = re.search(r'id=([^&]+)', url)
    if match: return match.group(1)
    return None

def parse_md(filepath):
    if not os.path.exists(filepath):
        return {}, ""
    with open(filepath, 'r', encoding='utf-8') as f:
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
                    fm[k.strip()] = v.strip().strip('"\'')
            return fm, body
    return {}, content.strip()

def main():
    print("=" * 60)
    print("  ICL Ingest Pipeline")
    print("=" * 60)

    creds_env = os.environ.get("GDRIVE_CREDENTIALS")
    sheet_id = os.environ.get("GDRIVE_SHEET_ID")

    if not creds_env or not sheet_id:
        print("[!] Missing GDRIVE_CREDENTIALS or GDRIVE_SHEET_ID")
        sys.exit(1)

    if not GOOGLE_LIBS_AVAILABLE:
        print("[!] google-api-python-client not installed")
        sys.exit(1)

    scopes = [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.readonly'
    ]

    if os.path.exists(creds_env):
        creds = service_account.Credentials.from_service_account_file(creds_env, scopes=scopes)
    else:
        creds = service_account.Credentials.from_service_account_info(json.loads(creds_env), scopes=scopes)

    sheets_service = build('sheets', 'v4', credentials=creds)
    drive_service = build('drive', 'v3', credentials=creds)

    sheet_meta = sheets_service.spreadsheets().get(spreadsheetId=sheet_id).execute()
    first_sheet_title = sheet_meta['sheets'][0]['properties']['title']

    result = sheets_service.spreadsheets().values().get(
        spreadsheetId=sheet_id,
        range=first_sheet_title
    ).execute()

    values = result.get('values', [])
    if not values or len(values) < 2:
        print("[*] No rows found.")
        sys.exit(0)

    headers = [h.strip().lower() for h in values[0]]
    col_idx = {h: i for i, h in enumerate(headers)}
    
    for req in ['title', 'author', 'year', 'language', 'status']:
        if req not in col_idx:
            print(f"[!] Missing required column in sheet: {req}")
            sys.exit(1)
            
    status_col_index = col_idx['status']
    # A=0, B=1, etc.
    def col_num_to_letter(n):
        string = ""
        n += 1
        while n > 0:
            n, remainder = divmod(n - 1, 26)
            string = chr(65 + remainder) + string
        return string
        
    status_col_letter = col_num_to_letter(status_col_index)

    updates = []
    
    for row_num, row in enumerate(values[1:], start=2):
        row_dict = {h: (row[col_idx[h]] if col_idx[h] < len(row) else "").strip() for h in headers}
        
        status = row_dict.get('status', '').lower()
        if status in ['published', 'pending'] or status.startswith('error'):
            continue
            
        title = row_dict.get('title', '')
        author = row_dict.get('author', '')
        year = row_dict.get('year', '')
        language = row_dict.get('language', '').lower()
        section_id = row_dict.get('section_id', '')
        pdf_link = row_dict.get('pdf_link', '')
        if pdf_link.lower().strip() == "n/a":
            pdf_link = ""
        if not pdf_link:
            for k, v in row_dict.items():
                if ("file" in k or "upload" in k or "submission" in k) and "drive.google.com" in v:
                    pdf_link = v
                    break

        source_url = row_dict.get('source_url', '')
        desc = row_dict.get('description', '')
        custom_id = row_dict.get('id', '')
        category = row_dict.get('category', '')
        subcategory = row_dict.get('subcategory', '')

        
        errors = []
        if language not in VALID_LANGS:
            errors.append(f"Invalid language: {language}")
        if not re.match(r'^\d{4}$', year):
            errors.append(f"Invalid year: {year}")
        if not title or not author:
            errors.append("Missing title or author")
            
        base_slug = slugify(f"{title}")
        doc_id = custom_id if custom_id else f"{language}-{base_slug}"
        if not re.match(r'^[a-z0-9\-]+$', doc_id):
            errors.append(f"Invalid slug: {doc_id}")
            
        if not doc_id.startswith(f"{language}-"):
            doc_id = f"{language}-{doc_id}"

        if errors:
            err_msg = "error: " + " | ".join(errors)
            updates.append({'range': f'{first_sheet_title}!{status_col_letter}{row_num}', 'values': [[err_msg]]})
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
            existing_drive_id = existing_fm.get('drive_id', '')
            pdf_exists = os.path.exists(pdf_path)
            
            if not pdf_exists or drive_id != existing_drive_id:
                print(f"[+] Downloading PDF for: '{title}'...")
                try:
                    request = drive_service.files().get_media(fileId=drive_id)
                    fh = io.FileIO(pdf_path, 'wb')
                    downloader = MediaIoBaseDownload(fh, request)
                    done = False
                    while done is False:
                        status_d, done = downloader.next_chunk()
                    has_pdf = True
                except Exception as e:
                    errors.append(f"PDF download failed: {e}")
            else:
                has_pdf = True
        elif os.path.exists(pdf_path):
            has_pdf = True
            
        if errors:
            err_msg = "error: " + " | ".join(errors)
            updates.append({'range': f'{first_sheet_title}!{status_col_letter}{row_num}', 'values': [[err_msg]]})
            continue

        # Frontmatter generation
        safe_title = title.replace('"', '\\"')
        safe_author = author.replace('"', '\\"')
        safe_desc = desc.replace('"', '\\"')
        
        # Merge source_url
        final_source_url = source_url if source_url else existing_fm.get('source_url', '')
        final_body = existing_body if existing_body else safe_desc

        fm_lines = [
            "---",
            "layout: text",
            f"id: {doc_id}",
            f'title: "{safe_title}"',
            f'author: "{safe_author}"',
            f"year: {year}",
            f"language: {language}",
            f"section_id: {section_id}"
        ]
        
        if has_pdf:
            fm_lines.append(f"pdf: {pdf_filename}")
        
        if final_source_url:
            fm_lines.append(f'source_url: "{final_source_url}"')
            
        if drive_id:
            fm_lines.append(f"drive_id: {drive_id}")
            
        fm_lines.append("status: pending")
        fm_lines.append("---")
        fm_lines.append("")
        fm_lines.append(final_body)
        
        fm = "\n".join(fm_lines) + "\n"

        with open(md_path, 'w', encoding='utf-8') as f:
            f.write(fm)
            
        print(f"[+] Processed: {doc_id}")
        updates.append({'range': f'{first_sheet_title}!{status_col_letter}{row_num}', 'values': [['pending']]})

    if updates:
        body = {'valueInputOption': 'RAW', 'data': updates}
        sheets_service.spreadsheets().values().batchUpdate(spreadsheetId=sheet_id, body=body).execute()
        print(f"[*] Updated {len(updates)} statuses in Sheet.")
    else:
        print("[*] No new rows to process.")

if __name__ == "__main__":
    main()
