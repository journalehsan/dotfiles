#!/usr/bin/env bash

# Script to apply nvim config fixes to other branches
# Usage: ./apply-nvim-to-branch.sh <branch-name>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <branch-name>"
    echo "Example: $0 laptop"
    exit 1
fi

BRANCH="$1"
CURRENT_BRANCH=$(git branch --show-current)

echo "=== Applying nvim fixes to branch: $BRANCH ==="
echo "Current branch: $CURRENT_BRANCH"
echo

# Stash any uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Stashing uncommitted changes..."
    git stash push -m "Auto-stash before nvim cherry-pick"
    STASHED=1
fi

# Switch to target branch
echo "Switching to branch: $BRANCH"
git checkout "$BRANCH"

echo
echo "Step 1: Cherry-picking nvim config files (0669e42)..."
if git cherry-pick 0669e42; then
    echo "✓ Nvim config files applied successfully"
else
    echo "✗ Conflict detected! Resolve conflicts and run:"
    echo "  git cherry-pick --continue"
    exit 1
fi

echo
echo "Step 2: Cherry-picking install.sh improvements..."
echo "Extracting only .gitignore and install.sh changes from e4c328f..."

# Create a temporary branch to extract only the files we want
git show e4c328f:.gitignore > .gitignore.tmp
git show e4c328f:install.sh > install.sh.tmp

# Apply the changes
mv .gitignore.tmp .gitignore
mv install.sh.tmp install.sh

git add .gitignore install.sh
git commit -m "Improve install.sh with nvim config verification checks

Cherry-picked from e4c328f (only .gitignore and install.sh changes)"

echo "✓ Install.sh improvements applied"

echo
echo "Step 3: Cherry-picking install.sh final fix (1ecd2d6)..."
if git cherry-pick 1ecd2d6; then
    echo "✓ Install.sh final fix applied successfully"
else
    echo "✗ Conflict detected! Resolve conflicts and run:"
    echo "  git cherry-pick --continue"
    exit 1
fi

echo
echo "=== ✓ All nvim fixes applied to branch: $BRANCH ==="
echo
echo "Verify the changes:"
echo "  git log --oneline -5"
echo "  ./install.sh"
echo
echo "If everything looks good, push the changes:"
echo "  git push origin $BRANCH"
echo
echo "To return to $CURRENT_BRANCH:"
echo "  git checkout $CURRENT_BRANCH"

if [ "$STASHED" = "1" ]; then
    echo "  git stash pop"
fi
