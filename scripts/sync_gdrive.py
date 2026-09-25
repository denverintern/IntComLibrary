#!/usr/bin/env python3
"""
Sync Google Drive / Google Form responses to the Internationalist Communist Library Jekyll site.

Supports two modes of fetching the Google Sheet:
1. Google Service Account (Recommended for private Sheets/Drive):
   Set GDRIVE_CREDENTIALS (raw JSON string or path to JSON key file) and
   GDRIVE_SHEET_ID (the spreadsheet ID from the URL).
2. Public Google Sheet CSV (Zero-config alternative):
   Set GDRIVE_SHEET_CSV_URL (the "Publish to the web" CSV link).

PDF files uploaded via Google Forms will have drive links in the sheet.
The script extracts file IDs, downloads new PDFs into `assets/uploads/`,
and generates/updates markdown files in `_texts/`.
"""

import os
import re
import sys
import json
import unicodedata
import urllib.request
import urllib.parse
import csv
import io

# Optional Google client libraries (used if GDRIVE_CREDENTIALS is provided)
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
SECTIONS_DIR = os.path.join(REPO_ROOT, "sections")

# Language code normalization map
LANG_MAP = {
    "en": "en", "english": "en", "ingles": "en", "inglês": "en",
    "es": "es", "spanish": "es", "español": "es", "espanol": "es",
    "pt": "pt", "portuguese": "pt", "português": "pt", "portugues": "pt",
    "it": "it", "italian": "it", "italiano": "it",
    "nl": "nl", "dutch": "nl", "nederlands": "nl",
    "de": "de", "german": "de", "deutsch": "de",
    "el": "el", "greek": "el", "ελληνικά": "el", "ellinika": "el",
    "fr": "fr", "french": "fr", "français": "fr", "francais": "fr",
    "ru": "ru", "russian": "ru", "русский": "ru", "russkiy": "ru",
    "tr": "tr", "turkish": "tr", "türkçe": "tr", "turkce": "tr",
    "pl": "pl", "polish": "pl", "polski": "pl",
    "zh": "zh", "chinese": "zh", "mandarin": "zh", "中文": "zh", "zhongwen": "zh",
    "ja": "ja", "japanese": "ja", "日本語": "ja", "nihongo": "ja",
    "ko": "ko", "korean": "ko", "한국어": "ko", "hanguk": "ko",
    "ar": "ar", "arabic": "ar", "العربية": "ar", "arab": "ar",
    "hi": "hi", "hindi": "hi", "हिन्दी": "hi",
    "bn": "bn", "bangla": "bn", "bengali": "bn", "বাংলা": "bn",
    "id": "id", "indonesian": "id", "bahasa": "id", "bahasa indonesia": "id"
}

def slugify(text):
    """Generate a clean URL/filename slug from a string."""
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('ascii')
    text = re.sub(r'[^\w\s-]', '', text.lower())
    return re.sub(r'[-\s]+', '-', text).strip('-_')

def normalize_language(raw_lang):
    """Normalize input language string to 2-letter ISO code."""
    if not raw_lang:
        return "en"
    cleaned = raw_lang.strip().lower()
    return LANG_MAP.get(cleaned, "en")

def extract_drive_id(url_or_id):
    """Extract Google Drive file ID from URL or return raw ID."""
    if not url_or_id:
        return None
    url_or_id = url_or_id.strip()
    # Match /d/<id> or id=<id>
    match = re.search(r'/d/([a-zA-Z0-9_-]+)', url_or_id)
    if match:
        return match.group(1)
    match = re.search(r'id=([a-zA-Z0-9_-]+)', url_or_id)
    if match:
        return match.group(1)
    # Check if raw ID
    if re.match(r'^[a-zA-Z0-9_-]{20,}$', url_or_id):
        return url_or_id
    return None

def download_drive_file_service_account(drive_service, file_id, destination_path):
    """Download file using Google Drive API and Service Account."""
    request = drive_service.files().get_media(fileId=file_id)
    with io.FileIO(destination_path, 'wb') as fh:
        downloader = MediaIoBaseDownload(fh, request)
        done = False
        while not done:
            status, done = downloader.next_chunk()
            if status:
                print(f"  Download progress: {int(status.progress() * 100)}%")

def download_drive_file_public(file_id, destination_path):
    """Download publicly accessible Google Drive file via standard export/uc URL."""
    url = f"https://drive.google.com/uc?export=download&id={file_id}"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    )
    with urllib.request.urlopen(req) as resp, open(destination_path, "wb") as f:
        # Check for Google Drive virus warning confirmation page
        content = resp.read()
        if b"Google Drive - Virus scan warning" in content:
            # Try to grab confirm token
            html_text = content.decode('utf-8', errors='ignore')
            confirm_match = re.search(r'confirm=([0-9A-Za-z_]+)', html_text)
            if confirm_match:
                confirm_token = confirm_match.group(1)
                confirm_url = f"{url}&confirm={confirm_token}"
                with urllib.request.urlopen(urllib.request.Request(confirm_url, headers=req.headers)) as confirm_resp:
                    f.write(confirm_resp.read())
                    return
        f.write(content)

def parse_sheet_rows(rows):
    """Parse sheet rows (list of dicts) with flexible column header mapping."""
    parsed = []
    for row in rows:
        title = None
        author = "Unknown"
        language = "en"
        description = ""
        drive_link = None
        section = ""

        for key, val in row.items():
            if not key or not val:
                continue
            k = key.strip().lower()
            v = val.strip()

            if any(t in k for t in ["title", "título", "titulo", "livro", "book"]):
                title = v
            elif any(a in k for a in ["author", "autor", "escritor"]):
                author = v
            elif any(l in k for l in ["language", "idioma", "lengua", "lang"]):
                language = normalize_language(v)
            elif any(d in k for d in ["desc", "resumo", "notes", "coment"]):
                description = v
            elif any(p in k for p in ["pdf", "file", "archivo", "arquivo", "upload", "drive"]):
                # May contain multiple URLs if multi-file enabled
                drive_link = v
            elif any(s in k for s in ["section", "sección", "seccion", "seção", "categoria"]):
                section = v

        if title:
            parsed.append({
                "title": title,
                "author": author,
                "language": language,
                "description": description,
                "drive_link": drive_link,
                "section": section
            })
    return parsed

def get_rows_from_service_account(creds_json, sheet_id):
    """Read rows from Google Sheet using Google Sheets API."""
    if not GOOGLE_LIBS_AVAILABLE:
        raise ImportError("google-api-python-client and google-auth are required for service account access.")
    
    if os.path.exists(creds_json):
        creds = service_account.Credentials.from_service_account_file(
            creds_json,
            scopes=[
                'https://www.googleapis.com/auth/spreadsheets.readonly',
                'https://www.googleapis.com/auth/drive.readonly'
            ]
        )
    else:
        info = json.loads(creds_json)
        creds = service_account.Credentials.from_service_account_info(
            info,
            scopes=[
                'https://www.googleapis.com/auth/spreadsheets.readonly',
                'https://www.googleapis.com/auth/drive.readonly'
            ]
        )

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
        return [], drive_service

    headers = [h.strip() for h in values[0]]
    rows = []
    for row in values[1:]:
        row_dict = {}
        for idx, header in enumerate(headers):
            row_dict[header] = row[idx] if idx < len(row) else ""
        rows.append(row_dict)

    return rows, drive_service

def get_rows_from_csv_url(csv_url):
    """Read rows from a publicly published Google Sheet CSV URL."""
    req = urllib.request.Request(
        csv_url,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode('utf-8')
        reader = csv.DictReader(io.StringIO(content))
        return list(reader), None

def main():
    print("=" * 60)
    print("  Internationalist Communist Library - Google Drive & Sheet Synchronizer")
    print("=" * 60)

    os.makedirs(TEXTS_DIR, exist_ok=True)
    os.makedirs(UPLOADS_DIR, exist_ok=True)

    creds_env = os.environ.get("GDRIVE_CREDENTIALS")
    sheet_id_env = os.environ.get("GDRIVE_SHEET_ID")
    csv_url_env = os.environ.get("GDRIVE_SHEET_CSV_URL")

    raw_rows = []
    drive_service = None

    if creds_env and sheet_id_env:
        print("[*] Connecting via Google Cloud Service Account...")
        try:
            raw_rows, drive_service = get_rows_from_service_account(creds_env, sheet_id_env)
        except Exception as e:
            print(f"[!] Error reading sheet with Service Account: {e}")
            sys.exit(1)
    elif csv_url_env:
        print("[*] Fetching Google Sheet via Public CSV URL...")
        try:
            raw_rows, drive_service = get_rows_from_csv_url(csv_url_env)
        except Exception as e:
            print(f"[!] Error fetching public CSV: {e}")
            sys.exit(1)
    else:
        print("[!] No credentials found!")
        print("Please configure one of the following:")
        print("  1. Service Account: Set GDRIVE_CREDENTIALS and GDRIVE_SHEET_ID")
        print("  2. Public CSV: Set GDRIVE_SHEET_CSV_URL")
        sys.exit(0)

    items = parse_sheet_rows(raw_rows)
    print(f"[*] Found {len(items)} entries in Google Sheet.")

    synced_count = 0
    downloaded_pdfs = 0

    for item in items:
        title = item["title"]
        author = item["author"]
        language = item["language"]
        desc = item["description"]
        drive_link = item["drive_link"]

        base_slug = slugify(f"{language}-{title}")
        md_filename = f"{base_slug}.md"
        pdf_filename = f"{base_slug}.pdf"
        md_path = os.path.join(TEXTS_DIR, md_filename)
        pdf_path = os.path.join(UPLOADS_DIR, pdf_filename)

        # Handle PDF download if drive link exists
        has_pdf = False
        drive_id = extract_drive_id(drive_link) if drive_link else None

        if drive_id:
            if not os.path.exists(pdf_path) or os.path.getsize(pdf_path) == 0:
                print(f"[+] Downloading PDF for: '{title}' (Drive ID: {drive_id})...")
                try:
                    if drive_service:
                        download_drive_file_service_account(drive_service, drive_id, pdf_path)
                    else:
                        download_drive_file_public(drive_id, pdf_path)
                    print(f"    Saved to: assets/uploads/{pdf_filename}")
                    downloaded_pdfs += 1
                    has_pdf = True
                except Exception as dl_err:
                    print(f"    [!] Failed to download PDF: {dl_err}")
            else:
                has_pdf = True
        elif os.path.exists(pdf_path):
            has_pdf = True

        # Generate markdown frontmatter and body
        safe_title = title.replace('"', '\\"')
        safe_author = author.replace('"', '\\"')
        safe_desc = desc.replace('"', '\\"')

        pdf_frontmatter = f'pdf: "{pdf_filename}"\n' if has_pdf else ''

        md_content = f"""---
layout: text
title: "{safe_title}"
author: "{safe_author}"
language: "{language}"
description: "{safe_desc}"
{pdf_frontmatter}---
{desc}
"""

        # Only write if content is new or changed
        needs_write = True
        if os.path.exists(md_path):
            with open(md_path, 'r', encoding='utf-8') as f:
                if f.read().strip() == md_content.strip():
                    needs_write = False

        if needs_write:
            with open(md_path, 'w', encoding='utf-8') as f:
                f.write(md_content)
            print(f"[+] Wrote text page: _texts/{md_filename}")
            synced_count += 1

    print("-" * 60)
    print(f"[✓] Sync complete: {synced_count} markdown pages updated, {downloaded_pdfs} PDFs downloaded.")
    print("=" * 60)

if __name__ == "__main__":
    main()
