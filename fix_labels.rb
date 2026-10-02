content = File.read('_layouts/text.html')

content.sub!(/\{\{ source_label \}\}/, "{{ source_label | default: 'Source:' }}")
content.sub!(/\{\{ pdf_local_label \}\}/, "{{ pdf_local_label | default: 'Local Archive PDF' }}")
content.sub!(/\{\{ html_external_label \}\}/, "{{ html_external_label | default: 'External HTML' }}")
content.sub!(/\{\{ open_pdf_label \}\}/, "{{ open_pdf_label | default: 'Open in Browser' }}")

File.write('_layouts/text.html', content)
