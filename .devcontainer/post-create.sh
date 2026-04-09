#!/usr/bin/env bash
# DevContainer post-create script - runs once when the container is created
set -e
trap 'true' PIPE

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC} $1"; }

cd /workspace
for env_file in ".env" ".env.dev"; do
    if [ -f "$env_file" ]; then
        set -a
        # shellcheck source=/dev/null
        source "$env_file"
        set +a
    fi
done
PROJECT_DIR="${DJANGO_PROJECT_DIR:-src}"

log_info "🚀 Starting DevContainer initialization..."

# ============================================================
# Stage 0: Clean VS Code server extension cache
# ============================================================
log_info "🧹 Stage 0: Cleaning VS Code server cache..."
if [ -d "/vscode/vscode-server/extensionsCache" ]; then
    (cd /vscode/vscode-server/extensionsCache && ls -t 2>/dev/null | tail -n +500 | xargs -r rm -rf 2>/dev/null || true) || log_warning "Cache cleanup encountered issues, continuing"
    log_success "VS Code server cache cleaned"
else
    log_info "VS Code server cache directory not found, skipping"
fi

# ============================================================
# Stage 1: Python environment setup
# ============================================================
log_info "📦 Stage 1: Setting up Python environment..."

if [ -d ".venv" ]; then
    log_info "Existing .venv found, attempting to reuse..."
    sudo chown -R "$(id -u):$(id -g)" .venv 2>/dev/null || log_warning "Cannot fix .venv owner"
    chmod -R u+rwX .venv 2>/dev/null || log_warning "Cannot fix .venv permissions"

    if uv venv .venv 2>/dev/null; then
        log_success ".venv reused (cache preserved)"
    else
        log_warning ".venv rebuild failed, clearing and retrying..."
        if sudo find .venv -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || \
            find .venv -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null; then
            log_success ".venv cleared"
        else
            log_error "Cannot clear .venv — check volume permissions and retry"
            exit 1
        fi

        if ! uv venv .venv; then
            log_error ".venv creation failed — check uv and volume permissions"
            exit 1
        fi
    fi
else
    mkdir -p .venv
    uv venv .venv
fi

source .venv/bin/activate

if [ -f "pyproject.toml" ]; then
    log_info "Installing from pyproject.toml..."
    uv pip install -e ".[dev]" || uv pip install -e "."
elif [ -f "requirements-dev.txt" ]; then
    log_info "Installing from requirements-dev.txt..."
    uv pip install -r requirements-dev.txt
elif [ -f "requirements.txt" ]; then
    log_info "Installing from requirements.txt..."
    uv pip install -r requirements.txt
else
    log_warning "No dependency file found (pyproject.toml / requirements*.txt)"
fi

log_success "Python environment ready"

# ============================================================
# Stage 2: Playwright browser install
# ============================================================
if .venv/bin/python -c "import playwright" >/dev/null 2>&1; then
    log_info "🌐 Stage 2: Installing Playwright browser..."
    mkdir -p ~/.cache/ms-playwright
    chmod -R 755 ~/.cache/ms-playwright

    if .venv/bin/python -m playwright install chromium --with-deps; then
        log_success "Playwright browser installed"
    else
        log_warning "Playwright install failed, attempting permission fix..."
        sudo chown -R "$(whoami):$(whoami)" ~/.cache/ms-playwright || true
        chmod -R 755 ~/.cache/ms-playwright || true
        .venv/bin/python -m playwright install chromium --with-deps \
            && log_success "Playwright browser installed (retry)" \
            || log_warning "Playwright install failed — E2E tests may not work"
    fi
else
    log_info "playwright not installed in venv, skipping browser install"
fi

# ============================================================
# Stage 3: CLI tool checks (agent-browser, openspec, dev tools)
# ============================================================
log_info "🤖 Stage 3: Verifying CLI tools..."

ARCHITECTURE="$(uname -m)"
if [ "$ARCHITECTURE" = "arm64" ] || [ "$ARCHITECTURE" = "aarch64" ]; then
    log_warning "agent-browser is skipped on ARM64; install Chromium manually if you need browser automation"
elif command -v agent-browser >/dev/null 2>&1; then
    if agent-browser install --with-deps; then
        log_success "agent-browser initialized"
    else
        agent-browser install \
            && log_success "agent-browser initialized (retry)" \
            || log_warning "agent-browser init failed — browser automation may not work"
    fi
else
    log_warning "agent-browser not found — check Dockerfile npm install"
fi

if command -v openspec >/dev/null 2>&1; then
    log_success "openspec available: $(openspec --version 2>/dev/null || echo 'installed')"
else
    log_warning "openspec not found — try: npx @fission-ai/openspec --help"
fi

for tool_name in rg fd ast-grep jq fzf gh lsof; do
    if command -v "$tool_name" >/dev/null 2>&1; then
        log_success "Tool available: $tool_name"
    else
        log_warning "Tool missing: $tool_name"
    fi
done

# ============================================================
# Stage 4: Django initialization
# ============================================================
if [ -f "/workspace/${PROJECT_DIR}/manage.py" ]; then
    log_info "🗄️  Stage 4: Django initialization ($PROJECT_DIR)..."
    (
        cd "/workspace/${PROJECT_DIR}"
        /workspace/.venv/bin/python manage.py migrate --noinput || log_warning "migrate failed"
        /workspace/.venv/bin/python manage.py collectstatic --noinput || log_warning "collectstatic failed"
    )
    log_success "Django initialization complete"
else
    log_warning "manage.py not found at /workspace/${PROJECT_DIR} — skipping Django init"
fi

log_success "✅ DevContainer post-create complete"
