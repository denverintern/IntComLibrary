content = File.read("_includes/archive.html")

content.sub!(/\{% case page\.language %\}.*?\{% endcase %\}/m, "")
# Wait, archive.html needs to define t just in case? No, it inherits from default.html, but index.html includes it. index.html uses default.html layout. So it's fine. 
# BUT `archive_title` etc. are used in archive.html. Let's just use `t` for everything and replace the variables.

File.write("_includes/archive.html", content)
