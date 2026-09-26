#!/usr/bin/env python3
import os
import sys
import json
try:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
except ImportError:
    sys.exit(0)

def parse_md_id(filepath):
    if not os.path.exists(filepath): return None
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            for line in parts[1].splitlines():
                if line.startswith("id:"):
                    return line.split(":", 1)[1].strip().strip('"\'')
    return None

def main():
    if len(sys.argv) < 2:
        sys.exit(0)
        
    changed_files = sys.argv[1:]
    published_ids = set()
    for f in changed_files:
        doc_id = parse_md_id(f)
        if doc_id:
            published_ids.add(doc_id)
            
    if not published_ids:
        sys.exit(0)
        
    creds_env = os.environ.get("GDRIVE_CREDENTIALS")
    sheet_id = os.environ.get("GDRIVE_SHEET_ID")
    if not creds_env or not sheet_id:
        sys.exit(0)
        
    scopes = ['https://www.googleapis.com/auth/spreadsheets']
    if os.path.exists(creds_env):
        creds = service_account.Credentials.from_service_account_file(creds_env, scopes=scopes)
    else:
        creds = service_account.Credentials.from_service_account_info(json.loads(creds_env), scopes=scopes)

    sheets_service = build('sheets', 'v4', credentials=creds)
    sheet_meta = sheets_service.spreadsheets().get(spreadsheetId=sheet_id).execute()
    first_sheet_title = sheet_meta['sheets'][0]['properties']['title']

    result = sheets_service.spreadsheets().values().get(
        spreadsheetId=sheet_id,
        range=first_sheet_title
    ).execute()

    values = result.get('values', [])
    if len(values) < 2:
        sys.exit(0)

    headers = [h.strip().lower() for h in values[0]]
    if 'id' not in headers or 'status' not in headers:
        sys.exit(0)
        
    id_col = headers.index('id')
    status_col = headers.index('status')
    
    def col_num_to_letter(n):
        s = ""
        n += 1
        while n > 0:
            n, remainder = divmod(n - 1, 26)
            s = chr(65 + remainder) + s
        return s
        
    status_letter = col_num_to_letter(status_col)
    updates = []
    
    for row_num, row in enumerate(values[1:], start=2):
        row_id = row[id_col].strip() if id_col < len(row) else ""
        if row_id in published_ids:
            updates.append({'range': f'{first_sheet_title}!{status_letter}{row_num}', 'values': [['published']]})

    if updates:
        body = {'valueInputOption': 'RAW', 'data': updates}
        sheets_service.spreadsheets().values().batchUpdate(spreadsheetId=sheet_id, body=body).execute()

if __name__ == "__main__":
    main()
