content = File.read("_includes/archive.html")

content.sub!(/>Index<\/button>/, ">{{ t.view_index_label | default: 'Index' }}</button>")
content.sub!(/>Catalog<\/button>/, ">{{ t.view_catalog_label | default: 'Catalog' }}</button>")
content.sub!(/>Bulletin<\/button>/, ">{{ t.view_bulletin_label | default: 'Bulletin' }}</button>")

File.write("_includes/archive.html", content)
