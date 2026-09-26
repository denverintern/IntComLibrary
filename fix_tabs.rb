content = File.read('_includes/manage_desk.html')

fix = <<~JS
        document.querySelectorAll('.role-lead-only').forEach(el => el.style.display = 'none');
        
        // Show the approvals tab for Center
        const approvalTabBtn = document.querySelector('[data-tab="tab-approvals"]');
        if (approvalTabBtn) approvalTabBtn.style.display = '';
        const approvalTabContent = document.getElementById('tab-approvals');
        if (approvalTabContent) approvalTabContent.style.display = 'block';

        document.querySelectorAll('.admin-tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.admin-tab-content').forEach(c => c.classList.remove('active'));
        
        if (approvalTabBtn) approvalTabBtn.classList.add('active');
        if (approvalTabContent) approvalTabContent.classList.add('active');

        // Hide "Add Book" tab button explicitly
        const addBtn = document.getElementById('tab-btn-add');
        if (addBtn) addBtn.style.display = 'none';
JS

content.sub!(/        document\.querySelectorAll\('\.role-lead-only'\)\.forEach\(el => el\.style\.display = 'none'\);.+?if \(addBtn\) addBtn\.style\.display = 'none';/m, fix)

File.write('_includes/manage_desk.html', content)
