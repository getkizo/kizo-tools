#!/usr/bin/env bash
# Initializes monorepo skeleton for all getkizo repos
set -e

WORK_DIR="/tmp/kizo-init"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

keep() { mkdir -p "$1" && touch "$1/.gitkeep"; }

write_root_pkg() {
  local name=$1 desc=$2
  cat > package.json <<EOF
{
  "name": "@getkizo/${name}",
  "version": "0.0.1",
  "description": "${desc}",
  "private": true,
  "workspaces": ["apps/*", "modules/*", "packages/*", "adapters/*"]
}
EOF
}

write_core_pkg() {
  local name=$1 desc=$2
  cat > package.json <<EOF
{
  "name": "@getkizo/${name}",
  "version": "0.0.1",
  "description": "${desc}",
  "private": true,
  "workspaces": ["packages/*"]
}
EOF
}

commit_push() {
  git add -A
  git commit -m "chore: initialize monorepo skeleton"
  git push origin main
}

# ──────────────────────────────────────────────
# kizo-core  (kernel — no apps or adapters)
# ──────────────────────────────────────────────

init_core() {
  echo "→ kizo-core"
  gh repo clone getkizo/kizo-core kizo-core -- --quiet
  cd kizo-core

  write_core_pkg "kizo-core" "Kernel: event bus, module registry, shared domain types, and design tokens"

  keep packages/event-bus/src
  keep packages/module-registry/src
  keep packages/domain-types/src
  keep packages/design-tokens/src

  cat > packages/event-bus/package.json <<'EOF'
{ "name": "@getkizo/event-bus", "version": "0.0.1", "main": "src/index.js" }
EOF
  cat > packages/module-registry/package.json <<'EOF'
{ "name": "@getkizo/module-registry", "version": "0.0.1", "main": "src/index.js" }
EOF
  cat > packages/domain-types/package.json <<'EOF'
{ "name": "@getkizo/domain-types", "version": "0.0.1", "main": "src/index.js" }
EOF
  cat > packages/design-tokens/package.json <<'EOF'
{ "name": "@getkizo/design-tokens", "version": "0.0.1", "main": "src/index.js" }
EOF

  commit_push
  cd ..
}

# ──────────────────────────────────────────────
# Sector repos
# ──────────────────────────────────────────────

init_sector() {
  local repo=$1 desc=$2; shift 2
  local modules=("$@")

  echo "→ $repo"
  gh repo clone getkizo/$repo $repo -- --quiet
  cd $repo

  write_root_pkg "$repo" "$desc"

  keep apps/shell/src

  for mod in "${modules[@]}"; do
    keep modules/$mod/src
    cat > modules/$mod/package.json <<EOF
{ "name": "@getkizo/${mod}", "version": "0.0.1", "main": "src/index.js" }
EOF
  done

  keep packages/shared/src
  keep adapters/.gitkeep && rmdir adapters/.gitkeep 2>/dev/null || true
  keep adapters

  cat > apps/shell/package.json <<EOF
{ "name": "@getkizo/${repo}-shell", "version": "0.0.1", "main": "src/index.js" }
EOF

  commit_push
  cd ..
}

# ──────────────────────────────────────────────
# Special repos
# ──────────────────────────────────────────────

init_tools() {
  echo "→ kizo-tools"
  gh repo clone getkizo/kizo-tools kizo-tools -- --quiet
  cd kizo-tools

  cat > package.json <<'EOF'
{
  "name": "@getkizo/kizo-tools",
  "version": "0.0.1",
  "description": "Developer tools, CLI, and scaffolding for the Kizo ecosystem",
  "private": true,
  "workspaces": ["tools/*"]
}
EOF

  keep tools/cli/src
  keep tools/scaffold/src
  keep tools/dev/src

  for t in cli scaffold dev; do
    cat > tools/$t/package.json <<EOF
{ "name": "@getkizo/tools-${t}", "version": "0.0.1", "main": "src/index.js" }
EOF
  done

  commit_push
  cd ..
}

init_website() {
  echo "→ getkizo.com"
  gh repo clone getkizo/getkizo.com getkizo.com -- --quiet
  cd getkizo.com

  keep src
  keep public

  cat > package.json <<'EOF'
{
  "name": "getkizo-com",
  "version": "0.0.1",
  "description": "Landing page and marketing site for getkizo.com",
  "private": true
}
EOF

  commit_push
  cd ..
}

init_brand() {
  echo "→ kizo-brand"
  gh repo clone getkizo/kizo-brand kizo-brand -- --quiet
  cd kizo-brand

  keep assets/logos
  keep assets/colors
  keep assets/typography
  keep assets/icons
  keep tokens

  commit_push
  cd ..
}

init_partners() {
  echo "→ kizo-partners"
  gh repo clone getkizo/kizo-partners kizo-partners -- --quiet
  cd kizo-partners

  cat > package.json <<'EOF'
{
  "name": "@getkizo/kizo-partners",
  "version": "0.0.1",
  "description": "Partner portal, onboarding materials, and integration guides",
  "private": true,
  "workspaces": ["portal/*", "docs/*"]
}
EOF

  keep portal/src
  keep docs

  commit_push
  cd ..
}

# ──────────────────────────────────────────────
# Run all
# ──────────────────────────────────────────────

init_core

init_sector kizo-food \
  "Kizo sector for restaurants, cafés, and coffee shops" \
  register orders kitchen-display stock menu

init_sector kizo-beauty \
  "Kizo sector for salons, spas, and barbershops" \
  appointments clients pos staff

init_sector kizo-auto \
  "Kizo sector for repair shops and service centers" \
  jobs parts service-history pos

init_sector kizo-retail \
  "Kizo sector for apparel, accessories, and boutiques" \
  pos inventory customers returns

init_sector kizo-grocery \
  "Kizo sector for grocery, convenience, and specialty food" \
  pos inventory scale expiry

init_sector kizo-health \
  "Kizo sector for medical practices, dental, and wellness" \
  appointments patients billing soap-notes

init_sector kizo-fitness \
  "Kizo sector for gyms, studios, and personal training" \
  memberships schedule attendance pos

init_sector kizo-professional \
  "Kizo sector for legal, accounting, and consulting" \
  time-tracking billing clients portal

init_sector kizo-home \
  "Kizo sector for plumbing, HVAC, electrical, and cleaning" \
  jobs dispatch estimates customers

init_sector kizo-hospitality \
  "Kizo sector for hotels, B&Bs, and vacation rentals" \
  rooms booking housekeeping channels

init_tools
init_website
init_brand
init_partners

echo ""
echo "✓ All repos initialized."
