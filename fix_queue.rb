content = File.read('_includes/manage_desk.html')

# Add a class to the body or container for CSS hiding
role_css = <<~JS
    function applyRolePermissions(role) {
      currentRole = role;
      sessionStorage.setItem('lib_auth_role', role);

      authModal.style.display = 'none';
      adminPanel.style.display = 'block';
      
      // Update data attribute for CSS targeting
      adminPanel.setAttribute('data-role', role);
JS

content.sub!(/    function applyRolePermissions\(role\) \{\n      currentRole = role;\n      sessionStorage.setItem\('lib_auth_role', role\);\n\n      authModal.style.display = 'none';\n      adminPanel.style.display = 'block';/, role_css)

File.write('_includes/manage_desk.html', content)
