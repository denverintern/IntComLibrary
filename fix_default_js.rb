content = File.read('_layouts/default.html')

content.gsub!(/const btnShelf = document\.getElementById\('view-btn-shelf'\);\n/, '')
content.gsub!(/const viewShelf = document\.getElementById\('view-shelf'\);\n/, '')
content.gsub!(/if \(viewShelf\) viewShelf\.style\.display = \(mode === 'shelf' \? 'grid' : 'none'\);\n/, '')
content.gsub!(/if \(btnShelf\) btnShelf\.classList\.toggle\('active', mode === 'shelf'\);\n/, '')
content.gsub!(/if \(btnCatalog && btnIndex && btnShelf\)/, 'if (btnCatalog && btnIndex)')
content.gsub!(/btnShelf\.addEventListener\('click', \(\) => setArchiveView\('shelf'\)\);\n/, '')

File.write('_layouts/default.html', content)
