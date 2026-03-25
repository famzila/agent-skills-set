#!/bin/bash

# ============================================================================
# Angular Quality Orchestrator - Install & Configure Phase
# ============================================================================
# Installs quality packages and creates deterministic config files.
# ESLint config (eslint.config.js) is NOT generated — it requires
# intelligent merging handled by the Agent Skill.
#
# Usage: ./configure_linters.sh [--style css|scss] [--package-manager pnpm|npm|yarn] [--rxjs auto|enabled|disabled]
#   --style            Project style format (default: css)
#   --package-manager  Package manager to use (auto-detected if not provided)
#   --rxjs             RxJS linting mode: auto (check package.json), enabled, disabled (default: auto)
# ============================================================================

set -e

# Parse arguments
STYLE="css"
PKG_MANAGER=""
RXJS_MODE="auto"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --style) STYLE="$2"; shift ;;
        --package-manager) PKG_MANAGER="$2"; shift ;;
        --rxjs) RXJS_MODE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🎨 Angular Quality Installation (style: $STYLE)"
echo "================================================="
echo ""

# Prerequisites check
if [ ! -f "angular.json" ]; then
    echo "❌ Not in Angular project root"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ git not found. Git is required for Husky hooks."
    exit 1
fi

# Determine package manager (if not provided)
if [ -z "$PKG_MANAGER" ]; then
    if command -v pnpm &> /dev/null; then
        PKG_MANAGER="pnpm"
        INSTALL_CMD="add"
    elif command -v yarn &> /dev/null; then
        PKG_MANAGER="yarn"
        INSTALL_CMD="add"
    else
        echo "⚠️  Neither pnpm nor yarn found. Using npm instead..."
        PKG_MANAGER="npm"
        INSTALL_CMD="install"
    fi
fi

# Set INSTALL_CMD based on PKG_MANAGER
case "$PKG_MANAGER" in
    pnpm|yarn) INSTALL_CMD="add" ;;
    npm) INSTALL_CMD="install" ;;
esac

echo "📦 Using package manager: $PKG_MANAGER"

# ============================================================================
# Step 1: Angular ESLint Base
# ============================================================================
echo "🔍 Installing Angular ESLint..."
npx -y ng add @angular-eslint/schematics --skip-confirmation
echo "✅ Base ESLint installed"
echo "🔎 Verifying base configuration..."
ng lint
echo "✅ Base configuration verified"
echo ""

# ============================================================================
# Step 2: Install Enhancement Packages
# ============================================================================
echo "📦 Installing ESLint, Prettier, and Git hooks packages..."
$PKG_MANAGER $INSTALL_CMD -D \
  eslint-plugin-import-x \
  eslint-import-resolver-typescript \
  @typescript-eslint/parser \
  eslint-plugin-unused-imports \
  prettier \
  eslint-config-prettier \
  eslint-plugin-prettier \
  globals \
  husky \
  lint-staged \
  @commitlint/cli \
  @commitlint/config-conventional

echo "✅ Base packages installed"

# Determine if eslint-plugin-rxjs-x should be installed
INSTALL_RXJS=false
if [ "$RXJS_MODE" = "enabled" ]; then
    INSTALL_RXJS=true
elif [ "$RXJS_MODE" = "auto" ]; then
    if grep -q '"rxjs"' package.json 2>/dev/null; then
        INSTALL_RXJS=true
        echo "ℹ️  RxJS detected in package.json — installing eslint-plugin-rxjs-x"
    else
        echo "ℹ️  RxJS not found in package.json — skipping eslint-plugin-rxjs-x"
    fi
fi

if [ "$INSTALL_RXJS" = true ]; then
    echo "📦 Installing RxJS linting plugin..."
    $PKG_MANAGER $INSTALL_CMD -D eslint-plugin-rxjs-x
    echo "✅ eslint-plugin-rxjs-x installed"
else
    echo "⏭️  Skipping eslint-plugin-rxjs-x (rxjs mode: $RXJS_MODE)"
fi

# ============================================================================
# Step 2b: Install Stylelint (conditional on style format)
# ============================================================================
if [ "$STYLE" = "scss" ]; then
    echo "📦 Installing Stylelint for SCSS..."
    $PKG_MANAGER $INSTALL_CMD -D \
      stylelint \
      stylelint-config-standard-scss
else
    echo "📦 Installing Stylelint for CSS..."
    $PKG_MANAGER $INSTALL_CMD -D \
      stylelint \
      stylelint-config-standard
fi

echo "✅ Stylelint installed"
echo ""

# ============================================================================
# Step 3: Husky Init
# ============================================================================
echo "🐶 Initializing Husky..."
$PKG_MANAGER exec husky init
echo "✅ Husky initialized"
echo ""

# ============================================================================
# Step 4: Generate Deterministic Config Files
# ============================================================================
echo "📝 Generating config files..."

# --- .prettierignore ---
cat > .prettierignore << 'EOF'
/.angular
/.nx
/coverage
/dist
node_modules
EOF
echo "  ✅ .prettierignore"

# --- .stylelintignore ---
cat > .stylelintignore << 'EOF'
/.angular
/.nx
/coverage
/dist
node_modules
EOF
echo "  ✅ .stylelintignore"

# --- stylelint.config.mjs (conditional) ---
if [ "$STYLE" = "scss" ]; then
cat > stylelint.config.mjs << 'EOF'
/** @type {import('stylelint').Config} */
export default {
  extends: ['stylelint-config-standard-scss'],
  rules: {
    'selector-class-pattern': null,
    'no-empty-source': null,
  },
};
EOF
else
cat > stylelint.config.mjs << 'EOF'
/** @type {import('stylelint').Config} */
export default {
  extends: ['stylelint-config-standard'],
  rules: {
    'selector-class-pattern': null,
    'no-empty-source': null,
  },
};
EOF
fi
echo "  ✅ stylelint.config.mjs ($STYLE)"

# --- commitlint.config.js ---
cat > commitlint.config.js << 'EOF'
module.exports = {
  extends: ['@commitlint/config-conventional'],
};
EOF
echo "  ✅ commitlint.config.js"

# --- .husky/commit-msg ---
cat > .husky/commit-msg << 'EOF'
npx --no -- commitlint --edit $1
EOF
echo "  ✅ .husky/commit-msg"

# --- .husky/pre-commit ---
if [ "$PKG_MANAGER" = "npm" ]; then
    PRE_COMMIT_CMD="npx lint-staged"
else
    PRE_COMMIT_CMD="$PKG_MANAGER exec lint-staged"
fi

cat > .husky/pre-commit << EOF
$PRE_COMMIT_CMD
EOF
echo "  ✅ .husky/pre-commit"

echo ""
echo "🎉 Installation & config generation complete!"
echo ""

echo "⚠️  eslint.config.js still uses the base Angular config."
echo "   Agent must now build the full config using:"
echo "   - references/eslint-config-template.md (skeleton structure)"
echo "   - references/*.md (individual plugin configs)"
echo "   Then add to package.json: scripts, prettier overrides, lint-staged config"

# ============================================================================
# Step 6: Verify All Generated Files
# ============================================================================
echo ""
echo "🔍 Verifying generated files..."
FILES=(".prettierignore" ".stylelintignore" "stylelint.config.mjs" "commitlint.config.js" ".husky/commit-msg" ".husky/pre-commit")
ALL_OK=true
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "  ✅ $f"
  else
    echo "  ❌ MISSING: $f"
    ALL_OK=false
  fi
done

if [ "$ALL_OK" = false ]; then
  echo ""
  echo "❌ Some files are missing. Do NOT proceed — revert the files listed above and retry. Do NOT run git reset --hard."
  exit 1
fi

echo ""
echo "✅ All config files verified. Agent may now proceed with ESLint plugin configuration."

