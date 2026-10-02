content = File.read('scripts/sync_gdrive.py')

# Fix markdown write
content.sub!(/        with open\(md_path, 'w', encoding='utf-8'\) as f:\n            f\.write\(fm\)\n            \n        print\(f"\[\+\] Processed: \{doc_id\}"\)/,
             "        if not dry_run:\n            with open(md_path, 'w', encoding='utf-8') as f:\n                f.write(fm)\n        print(f\"[+] Processed{' (DRY RUN)' if dry_run else ''}: {doc_id}\")")

# Fix PDF download
pdf_download_block = <<~PYTHON
                print(f"[+] Downloading PDF for: '{title}'...")
                if not dry_run:
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
                    print("    (DRY RUN: skipping download)")
                    has_pdf = True
PYTHON

content.sub!(/                print\(f"\[\+\] Downloading PDF for: '\{title\}'\.\.\."\)\n                try:.*?has_pdf = True\n                except Exception as e:\n                    errors\.append\(f"PDF download failed: \{e\}"\)/m, pdf_download_block.chomp)

# Fix sheets update
sheets_update_block = <<~PYTHON
    if updates:
        if not dry_run:
            body = {'valueInputOption': 'RAW', 'data': updates}
            sheets_service.spreadsheets().values().batchUpdate(spreadsheetId=sheet_id, body=body).execute()
            print(f"[*] Updated {len(updates)} statuses in Sheet.")
        else:
            print(f"[*] DRY RUN: Would have updated {len(updates)} statuses in Sheet.")
PYTHON

content.sub!(/    if updates:\n        body = \{'valueInputOption': 'RAW', 'data': updates\}\n        sheets_service\.spreadsheets\(\)\.values\(\)\.batchUpdate\(spreadsheetId=sheet_id, body=body\)\.execute\(\)\n        print\(f"\[\*\] Updated \{len\(updates\)\} statuses in Sheet\."\)/m, sheets_update_block.chomp)

File.write('scripts/sync_gdrive.py', content)
