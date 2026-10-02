content = File.read('scripts/mark_published.py')

import_re = <<~PYTHON
import json
import re
PYTHON

content.sub!(/import json/, import_re.chomp)

slugify_func = <<~PYTHON
def slugify(text):
    text = text.lower()
    text = re.sub(r'[^a-z0-9\\-]+', '-', text)
    return text.strip('-')
PYTHON

content.sub!(/def parse_md_id/, slugify_func + "\n\ndef parse_md_id")

row_id_fallback = <<~PYTHON
    title_col = headers.index('title') if 'title' in headers else -1
    lang_col = headers.index('language') if 'language' in headers else -1
    
    for row_num, row in enumerate(values[1:], start=2):
        row_id = row[id_col].strip() if id_col < len(row) else ""
        if not row_id and title_col >= 0 and lang_col >= 0:
            title = row[title_col].strip() if title_col < len(row) else ""
            lang = row[lang_col].strip() if lang_col < len(row) else ""
            if title and lang:
                row_id = f"{lang.lower()}-{slugify(title)}"
                
        if row_id in published_ids:
            updates.append({'range': f'{first_sheet_title}!{status_letter}{row_num}', 'values': [['published']]})
PYTHON

content.sub!(/    for row_num, row in enumerate\(values\[1:\], start=2\):\n        row_id = row\[id_col\]\.strip\(\) if id_col < len\(row\) else ""\n        if row_id in published_ids:\n            updates\.append\(\{'range': f'\{first_sheet_title\}!\{status_letter\}\{row_num\}', 'values': \[\['published'\]\]\}\)/m, row_id_fallback.chomp)

File.write('scripts/mark_published.py', content)
