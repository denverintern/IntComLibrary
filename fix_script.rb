content = File.read('scripts/sync_gdrive.py')

content.sub!(/def main\(\):/, "def main():\n    dry_run = os.environ.get('DRY_RUN', 'false').lower() == 'true'\n    if dry_run: print('--- DRY RUN MODE: No files or sheets will be modified ---')")

content.sub!(/update_sheet_status\(row\['row_idx'\], f"pending: {doc_id}"\)/, 
"if not dry_run: update_sheet_status(row['row_idx'], f\"pending: {doc_id}\")\n            else: print(f\"DRY RUN: Would update sheet row {row['row_idx']} to pending\")")

content.sub!(/update_sheet_status\(row\['row_idx'\], f"error: {str\(e\)}"\)/,
"if not dry_run: update_sheet_status(row['row_idx'], f\"error: {str(e)}\")\n            else: print(f\"DRY RUN: Would set error on row {row['row_idx']}\")")

content.sub!(/with open\(file_path, 'w', encoding='utf-8'\) as f:\n                f\.write\(new_content\)/,
"if not dry_run:\n                with open(file_path, 'w', encoding='utf-8') as f:\n                    f.write(new_content)\n            else:\n                print(f\"DRY RUN: Would write to {file_path}\")")

content.sub!(/download_file_from_google_drive\(file_id, pdf_path\)/,
"if not dry_run: download_file_from_google_drive(file_id, pdf_path)\n                else: print(f\"DRY RUN: Would download PDF {file_id}\")")

File.write('scripts/sync_gdrive.py', content)
