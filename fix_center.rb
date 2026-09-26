content = File.read('_includes/manage_desk.html')

# Add DEFAULT_CENTER_PASS
content.sub!(
  "const DEFAULT_MOD_PASS = 'mod-desk-1921';",
  "const DEFAULT_MOD_PASS = 'mod-desk-1921';\n    const DEFAULT_CENTER_PASS = 'center-desk-1926';"
)

content.sub!(
  "function getModPasscode() {\n      return localStorage.getItem('lib_mod_passcode') || DEFAULT_MOD_PASS;\n    }",
  "function getModPasscode() {\n      return localStorage.getItem('lib_mod_passcode') || DEFAULT_MOD_PASS;\n    }\n\n    function getCenterPasscode() {\n      return localStorage.getItem('lib_center_passcode') || DEFAULT_CENTER_PASS;\n    }"
)

# Update applyRolePermissions
role_logic = <<~JS
      } else if (role === 'center') {
        roleBadge.className = 'role-badge center';
        roleBadge.style.background = '#e3e3e3';
        roleBadge.style.color = '#333';
        roleBadge.textContent = 'Archival Center (View Only)';
        roleDescText.textContent = 'Read-only access to view the editorial desk and unreleased pipeline texts. Modifications disabled.';
        
        document.querySelectorAll('.role-lead-only').forEach(el => el.style.display = 'none');
        
        document.querySelectorAll('.admin-tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.admin-tab-content').forEach(c => c.classList.remove('active'));
        const qTab = document.getElementById('tab-btn-queue');
        if (qTab) qTab.classList.add('active');
        const qCont = document.getElementById('tab-queue');
        if (qCont) qCont.classList.add('active');

        // Hide "Add Book" tab button explicitly
        const addBtn = document.getElementById('tab-btn-add');
        if (addBtn) addBtn.style.display = 'none';

        if (btnDownloadBook) btnDownloadBook.style.display = 'none';
        if (btnCopyBook) btnCopyBook.style.display = 'none';
        if (btnSubmitApproval) btnSubmitApproval.style.display = 'none';
        if (modNoticeBanner) modNoticeBanner.style.display = 'none';

        renderSubmissionsQueue();
        
        // Hide edit/dismiss buttons in queue
        setTimeout(() => {
          document.querySelectorAll('.btn-sm').forEach(b => {
             if (b.textContent.includes('Dismiss') || b.textContent.includes('Approve') || b.textContent.includes('Load into Editor')) {
               b.style.display = 'none';
             }
          });
        }, 50);
      }
JS

content.sub!(/      \} else if \(role === 'moderator'\) \{.+?      \}/m) do |match|
  match + "\n" + role_logic
end

# Update login block
auth_block = <<~JS
    // Check existing session
    if (currentRole === 'lead_admin' || currentRole === 'moderator' || currentRole === 'center') {
JS
content.sub!("if (currentRole === 'lead_admin' || currentRole === 'moderator') {", auth_block)

login_logic = <<~JS
      const modPass = getModPasscode();
      const centerPass = getCenterPasscode();

      if (entered === adminPass) {
        authError.style.display = 'none';
        passInput.value = '';
        applyRolePermissions('lead_admin');
      } else if (entered === modPass) {
        authError.style.display = 'none';
        passInput.value = '';
        applyRolePermissions('moderator');
      } else if (entered === centerPass) {
        authError.style.display = 'none';
        passInput.value = '';
        applyRolePermissions('center');
      } else {
JS
content.sub!(/      const modPass = getModPasscode\(\);\s+if \(entered === adminPass\) \{.*?      \} else \{/m, login_logic)

# Update HTML inputs for passcode
pass_html = <<~HTML
        <div style="margin-bottom: 0.75rem;">
          <label class="metadata-label">Moderator Passcode</label>
          <input type="text" id="cfg-mod-pass" class="search-input" style="padding-left: 1rem;">
        </div>
        <div style="margin-bottom: 1.5rem;">
          <label class="metadata-label">Center Passcode (View Only)</label>
          <input type="text" id="cfg-center-pass" class="search-input" style="padding-left: 1rem;">
        </div>
HTML
content.sub!(/<div style="margin-bottom: 1\.5rem;">\s*<label class="metadata-label">Moderator Passcode<\/label>\s*<input type="text" id="cfg-mod-pass" class="search-input" style="padding-left: 1rem;">\s*<\/div>/m, pass_html)

# Update Passcode JS logic
save_pass_logic = <<~JS
    const cfgAdminPass = document.getElementById('cfg-admin-pass');
    const cfgModPass = document.getElementById('cfg-mod-pass');
    const cfgCenterPass = document.getElementById('cfg-center-pass');

    cfgAdminPass.value = getAdminPasscode();
    cfgModPass.value = getModPasscode();
    cfgCenterPass.value = getCenterPasscode();

    document.getElementById('btn-save-passcodes').addEventListener('click', () => {
      const newAdmin = cfgAdminPass.value.trim();
      const newMod = cfgModPass.value.trim();
      const newCenter = cfgCenterPass.value.trim();

      if (!newAdmin || !newMod || !newCenter) {
        alert('Passcodes cannot be empty.');
        return;
      }

      localStorage.setItem('lib_admin_passcode', newAdmin);
      localStorage.setItem('lib_mod_passcode', newMod);
      localStorage.setItem('lib_center_passcode', newCenter);
      alert('Editorial passcodes updated successfully!');
    });

    document.getElementById('btn-reset-passcodes').addEventListener('click', () => {
      if (confirm('Reset passcodes to initial factory defaults?')) {
        localStorage.removeItem('lib_admin_passcode');
        localStorage.removeItem('lib_mod_passcode');
        localStorage.removeItem('lib_center_passcode');
        cfgAdminPass.value = DEFAULT_ADMIN_PASS;
        cfgModPass.value = DEFAULT_MOD_PASS;
        cfgCenterPass.value = DEFAULT_CENTER_PASS;
        alert(`Passcodes reset:\\nLead Admin: ${DEFAULT_ADMIN_PASS}\\nModerator: ${DEFAULT_MOD_PASS}\\nCenter: ${DEFAULT_CENTER_PASS}`);
      }
    });
JS

content.sub!(/    const cfgAdminPass = document\.getElementById\('cfg-admin-pass'\);.*?    \}\);\s*\n/m, save_pass_logic)

File.write('_includes/manage_desk.html', content)
