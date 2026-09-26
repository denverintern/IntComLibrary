content = File.read('_includes/manage_desk.html')

style_block = <<~HTML
<!-- Authentication Gate Modal (Displayed when locked) -->
<style>
  [data-role="center"] .btn-approve,
  [data-role="center"] .btn-edit-submission,
  [data-role="center"] .btn-reject {
    display: none !important;
  }
</style>
HTML

content.sub!("<!-- Authentication Gate Modal (Displayed when locked) -->", style_block)
File.write('_includes/manage_desk.html', content)
