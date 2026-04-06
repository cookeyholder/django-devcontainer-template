# django-devcontainer-template

Reusable DevContainer template for Django projects (Python 3.13 + uv + PostgreSQL + Redis + Playwright).

## What this template includes

- DevContainer with Docker Compose (`app`, `db`, `redis`)
- Python 3.13 base image + `uv`
- Common dev tools: `ruff`, `djlint`, `pre-commit`, `pip-audit`, `gh`, `rg`, `fd`, `jq`, `yq`, `fzf`
- Pinned Node CLIs: `@ast-grep/cli`, `@fission-ai/openspec`, `agent-browser`
- Post-create script with staged initialization (VS Code cache cleanup, venv bootstrap, Playwright, CLI checks, Django init)
- Post-start script to install pre-commit hooks and auto-start Django dev server (with startup verification)
- VS Code extensions pre-configured: ruff, djlint, Playwright, Copilot, Claude, material icons, git-graph, and more
- Optional Celery + Celery Beat services (commented out in compose — uncomment to enable)
- Utility scripts: `rebuild.sh` (full cleanup) and `setup-pre-commit.sh`

## Quick start

1. Create a new repository from this template folder.
2. Put your Django project in the repo (default assumes `manage.py` is in `src/`).
3. (Optional) copy env defaults: `cp .env.example .env.dev`
4. Open in VS Code and run `Dev Containers: Reopen in Container`.
5. Wait for post-create initialization (~3-5 minutes on first run).

## Expected project layout

By default:

- Django root: `/workspace/src`
- `manage.py`: `/workspace/src/manage.py`
- Virtual environment: `/workspace/.venv`

If your layout differs, set these variables in `.env.dev`:

```env
DJANGO_PROJECT_DIR=src
DJANGO_SETTINGS_MODULE=config.settings
```

## Dependency install behavior in post-create

The script tries in this order:

1. `uv pip install -e ".[dev]"` (if `pyproject.toml` exists)
2. `uv pip install -r requirements-dev.txt` (if exists)
3. `uv pip install -r requirements.txt` (if exists)

## Optional `.env.dev`

Create `.env.dev` to override service defaults:

```env
DJANGO_SETTINGS_MODULE=config.settings
DJANGO_PROJECT_DIR=src
POSTGRES_DB=app
POSTGRES_USER=app
POSTGRES_PASSWORD=app
POSTGRES_HOST=db
POSTGRES_PORT=5432
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=dev_password
```

## Enabling Celery

Uncomment the `celery` block in `.devcontainer/docker-compose.dev.yml` and adjust the startup command to match your project's Celery app module.

## Utility scripts

| Script                              | Purpose                                                                                 |
| ----------------------------------- | --------------------------------------------------------------------------------------- |
| `.devcontainer/rebuild.sh`          | Stop containers, remove volumes (optional), prune Docker, ready for `Rebuild Container` |
| `.devcontainer/setup-pre-commit.sh` | Install/re-install pre-commit hooks and configure git identity                          |

## Post-create initialization stages

| Stage | Description                                                                                   |
| ----- | --------------------------------------------------------------------------------------------- |
| 0     | VS Code server extension cache cleanup (prevents SIGPIPE errors)                              |
| 1     | Python venv bootstrap with robust recovery (preserves cached packages on rebuild)             |
| 2     | Playwright chromium browser install                                                           |
| 3     | CLI tool verification: `agent-browser`, `openspec`, `rg`, `fd`, `ast-grep`, `jq`, `fzf`, `gh` |
| 4     | Django `migrate` + `collectstatic` (skipped if `manage.py` not found)                         |

## One-time checks after container starts

```bash
python --version
uv --version
/workspace/.venv/bin/python -m django --version
pre-commit --version
openspec --version
agent-browser --help
/workspace/.venv/bin/python -m playwright --help
```

## Notes

- Gitleaks runs via pre-commit hook (`pre-commit run gitleaks --all-files`).
- This template avoids project-specific fixture loading — add your own `loaddata` call in `post-create.sh` if needed.
- `mypy-cache` volume is mounted to speed up type checking across rebuilds.
