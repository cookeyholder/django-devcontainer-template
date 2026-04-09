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

is_port_in_use() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1
}

is_django_server_responsive() {
    curl -fsS --max-time 1 http://127.0.0.1:8000/ >/dev/null 2>&1
}

describe_port_owner() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN 2>/dev/null || true
}

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
DJANGO_LOG_FILE="/tmp/django-devserver.log"

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

# Keep the database schema current on every start.
if [ -x "/workspace/.venv/bin/python" ] && [ -f "/workspace/${PROJECT_DIR}/manage.py" ]; then
    log_info "Running Django migrate..."
    if (
        cd "/workspace/${PROJECT_DIR}"
        /workspace/.venv/bin/python manage.py migrate --noinput
    ); then
        log_success "Django migrate completed"
    else
        log_warning "Django migrate failed — continuing with post-start hooks"
    fi

    # Auto-start Django dev server if the port is free.
    if is_django_server_responsive; then
        log_info "Django dev server is already responding on http://127.0.0.1:8000, skipping"
    elif is_port_in_use 8000; then
        log_warning "Port 8000 is already in use, skipping Django auto-start"
        describe_port_owner 8000
    else
        log_info "Starting Django dev server (0.0.0.0:8000)..."
        (
            cd "/workspace/${PROJECT_DIR}"
            nohup /workspace/.venv/bin/python manage.py runserver 0.0.0.0:8000 --noreload \
                >"$DJANGO_LOG_FILE" 2>&1 &
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
            log_warning "Django dev server may not have started — check $DJANGO_LOG_FILE"
        fi
    fi
else
    log_warning "venv or manage.py not found — skipping Django auto-start"
fi

log_success "✅ Post-start hooks complete"
