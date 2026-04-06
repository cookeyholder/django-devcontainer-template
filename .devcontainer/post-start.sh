#!/usr/bin/env bash
# DevContainer post-start script - runs every time the container starts
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

cd /workspace
PROJECT_DIR="${DJANGO_PROJECT_DIR:-src}"

log_info "🚀 Running post-start hooks..."

# Install pre-commit hooks
if command -v pre-commit >/dev/null 2>&1 && [ -f ".pre-commit-config.yaml" ]; then
    pre-commit install --hook-type pre-commit --hook-type pre-push >/dev/null 2>&1 \
        && log_success "pre-commit hooks installed" \
        || log_warning "pre-commit install failed — run manually: pre-commit install"

    # Run an explicit template lint pass on every container start.
    pre-commit run djlint-django --all-files >/dev/null 2>&1 \
        && log_success "djlint template check passed" \
        || log_warning "djlint template check found issues — run manually: pre-commit run djlint-django --all-files"
fi

# Auto-start Django dev server if not already running
if [ -x "/workspace/.venv/bin/python" ] && [ -f "/workspace/${PROJECT_DIR}/manage.py" ]; then
    DJANGO_CMD_PATTERN="manage.py runserver 0.0.0.0:8000"
    if pgrep -f "$DJANGO_CMD_PATTERN" >/dev/null 2>&1; then
        log_info "Django dev server already running, skipping"
    else
        log_info "Starting Django dev server (0.0.0.0:8000)..."
        (
            cd "/workspace/${PROJECT_DIR}"
            nohup /workspace/.venv/bin/python manage.py runserver 0.0.0.0:8000 --noreload \
                >/tmp/django-devserver.log 2>&1 &
        )

        # Wait up to 10 seconds to confirm the server is reachable
        started=false
        for _ in {1..10}; do
            if curl -fsS --max-time 1 http://127.0.0.1:8000/ >/dev/null 2>&1; then
                started=true
                break
            fi
            sleep 1
        done

        if [ "$started" = true ]; then
            log_success "Django dev server started: http://localhost:8000"
        else
            log_warning "Django dev server may not have started — check /tmp/django-devserver.log"
        fi
    fi
else
    log_warning "venv or manage.py not found — skipping Django auto-start"
fi

log_success "✅ Post-start hooks complete"
