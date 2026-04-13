#!/usr/bin/env bash
# Sync AI skills from cookeyholder/using-ai-skills into .agent/skills.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_REPO_URL="${AI_SKILLS_REPO_URL:-https://github.com/cookeyholder/using-ai-skills.git}"
TARGET_DIR="$PROJECT_ROOT/.agent/skills"
WORK_DIR="$(mktemp -d)"
SOURCE_DIR="$WORK_DIR/using-ai-skills"

cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

log_info() {
    printf '\033[0;34m[INFO]\033[0m %s\n' "$1"
}

log_success() {
    printf '\033[0;32m[OK]\033[0m %s\n' "$1"
}

log_warning() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$1"
}

log_info "Syncing AI skills from ${SOURCE_REPO_URL}..."
git clone --depth 1 "$SOURCE_REPO_URL" "$SOURCE_DIR"

mkdir -p "$TARGET_DIR"
find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

skill_count=0
for skill_path in "$SOURCE_DIR"/*; do
    [ -d "$skill_path" ] || continue
    [ -f "$skill_path/SKILL.md" ] || continue

    skill_name="$(basename "$skill_path")"
    rm -rf "$TARGET_DIR/$skill_name"
    cp -a "$skill_path" "$TARGET_DIR/"
    skill_count=$((skill_count + 1))
done

if [ "$skill_count" -eq 0 ]; then
    log_warning "No skills were found in the source repository"
    exit 1
fi

log_success "Synced ${skill_count} skills into .agent/skills"
