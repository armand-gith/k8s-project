#!/bin/bash
set -e

# 1. Resolve Repo Root & Load .env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [ -f "$REPO_ROOT/.env" ]; then
  source "$REPO_ROOT/.env"
else
  echo "Error: .env file missing in $REPO_ROOT"
  exit 1
fi

# 2. Pre-Flight Check: GitHub CLI Authentication
echo "==> Verifying GitHub CLI authentication..."
if ! gh auth status >/dev/null 2>&1; then
  echo "Error: You are not logged into GitHub."
  echo "Run 'gh auth login' in your terminal first."
  exit 1
fi

echo "==> Authenticated as: $(gh api user -q .login)"

# 3. Git Initialization & Repo Creation
echo "==> Initializing Git repository in $REPO_ROOT..."
git init
git config user.name "$GITHUB_USER"
git branch -M main

echo "==> Creating GitHub repository ($REPO_NAME)..."
gh repo create "$REPO_NAME" --public --source=. --remote=origin || true

echo "==> Making initial commit..."
git add .
git commit -m "feat: initial monorepo layout and setup scripts"
git push -u origin main

# 4. Set Branch Protection
echo "==> Enforcing branch protection rules on main..."
gh api -X PUT "repos/$GITHUB_USER/$REPO_NAME/branches/main/protection" \
  -F "required_status_checks=null" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=1" \
  -F "restrictions=null"

echo "==> Bootstrap Complete!"