#!/usr/bin/env bash
# Configures canonical PR labels and 1-approving-review branch protection on `main`.
set -euo pipefail

REPO="${REPO:-denverintern/IntComLibrary}"

echo "[*] Creating canonical editorial PR labels on ${REPO}..."
gh label create "ingest" --repo "$REPO" --color "0E8A16" --description "Automated or manual text ingestion" --force
gh label create "needs-review" --repo "$REPO" --color "FBCA04" --description "Requires moderator checklist verification" --force
gh label create "has-pdf" --repo "$REPO" --color "1D76DB" --description "Includes local PDF in assets/uploads/" --force
gh label create "empty-source" --repo "$REPO" --color "D93F0B" --description "Missing external source_url in frontmatter" --force

echo "[*] Applying branch protection on ${REPO} (branch: main, required approving reviews: 1)..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/main/protection" \
  --input - << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["editorial-desk-check"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo "[+] Branch protection and editorial labels configured."
