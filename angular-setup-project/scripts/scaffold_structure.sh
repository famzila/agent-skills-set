#!/bin/bash

# Standard Angular Folder Scaffolding Script
# Ensures a consistent production-ready directory structure

PROJECT_ROOT=${1:-"."}

echo "🚀 Scaffolding Angular directory structure in: $PROJECT_ROOT"

DIRS=(
  "src/app/core"
  "src/app/shared"
  "src/app/features"
)

for dir in "${DIRS[@]}"; do
  full_path="$PROJECT_ROOT/$dir"
  if [ ! -d "$full_path" ]; then
    mkdir -p "$full_path"
    echo "✅ Created: $dir"
  else
    echo "ℹ️  Skipped: $dir (already exists)"
  fi
done

echo "🎉 Scaffolding complete!"
