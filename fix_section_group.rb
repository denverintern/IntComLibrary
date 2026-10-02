content = File.read('_includes/archive.html')
content.sub!(/<section class="index-section-group">/, '<section class="index-section-group" data-section-group="{{ s_slug }}">')
File.write('_includes/archive.html', content)
