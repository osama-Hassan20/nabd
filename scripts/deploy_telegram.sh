#!/usr/bin/env bash
set -e

WORKFLOW_FILE="main.yml"
BRANCH=$(git branch --show-current || echo "main")

echo "🚀 Triggering GitHub Action: Flutter Build & Deploy to Telegram"
echo "📌 Branch: $BRANCH"

if ! command -v gh &> /dev/null; then
  echo "❌ Error: GitHub CLI ('gh') is not installed."
  echo "👉 You can install it using: brew install gh"
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "⚠️ You are not logged in to GitHub CLI."
  echo "👉 Please run: gh auth login"
  exit 1
fi

echo "⏳ Sending workflow dispatch event..."
gh workflow run "$WORKFLOW_FILE" --ref "$BRANCH"

echo ""
echo "✅ Workflow triggered successfully!"
echo "🔗 View runs: https://github.com/mahmoudSobhiAwad/purexo/actions/workflows/$WORKFLOW_FILE"
echo ""
echo "💡 To watch the build progress live in your terminal, run:"
echo "   gh run watch"
