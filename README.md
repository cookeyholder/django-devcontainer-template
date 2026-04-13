# django-devcontainer-template

適用於 Django 專案的可重複使用 DevContainer 範本，採用 **Python 3.13 + uv + PostgreSQL + Redis + Playwright**，並內建 **Docker-in-Docker（DinD）** 支援。

## 包含內容

### 基礎環境

- 基底映像：`python:3.13-slim-trixie`（Debian Trixie 官方 Python slim 映像）
- Docker Compose 服務：`app`、`db`（PostgreSQL 15）、`redis`（Redis 7）
- Python 套件管理器：[uv](https://github.com/astral-sh/uv)（高速，取代 pip/pip-tools）
- Docker-in-Docker（DinD）：可在容器內執行完整 Docker daemon

### 開發工具（預先安裝）

| 工具            | 說明                                                              |
| --------------- | ----------------------------------------------------------------- |
| `ruff`          | Python 程式碼格式化與 lint                                        |
| `djlint`        | Django HTML 範本 lint                                             |
| `pre-commit`    | Git 提交前檢查hook                                                |
| `pip-audit`     | Python 相依套件安全性掃描                                         |
| `gh`            | GitHub CLI                                                        |
| `rg`（ripgrep） | 快速全文搜尋                                                      |
| `fd`            | 快速檔案搜尋（`find` 替代方案）                                   |
| `lsof`          | 檢查 port 佔用狀態                                                |
| `jq` / `yq`     | JSON / YAML 命令列處理                                            |
| `fzf`           | 互動式模糊搜尋                                                    |
| `ast-grep`      | 基於 AST 的程式碼結構搜尋                                         |
| `gh copilot`    | GitHub Copilot CLI（`gh copilot explain` / `gh copilot suggest`） |

### 固定版本的 Node CLI 工具

| 套件                   | 說明                      |
| ---------------------- | ------------------------- |
| `@ast-grep/cli`        | AST 搜尋 CLI              |
| `@fission-ai/openspec` | OpenSpec 工作流程 CLI     |
| `agent-browser`        | AI agent 瀏覽器自動化工具 |

### VS Code 整合

以下擴充套件已預先設定：

- Python / Pylance / Ruff / djlint
- GitHub Copilot Chat / Claude Code / OpenSpec
- Playwright 測試執行器
- Docker、Git Graph、Material Icons、FiraCode 字型
- Markdown 預覽增強、CSV Rainbow、Color Highlight 等

### AI Skills

- `.agent/skills/` 已同步 `cookeyholder/using-ai-skills` 的 skill 內容，讓 AI agent 可以直接讀取本機 skills。
- 若 upstream skills 有更新，可執行 `scripts/sync-ai-skills.sh` 重新同步。
- 同步腳本會重新複製所有具有 `SKILL.md` 的 skill 目錄，並保留各 skill 內的附屬檔案。

### 腳本與生命週期

- **initializeCommand**：建構前檢查主機連接埠 `8000`、`5432`、`6379` 是否可用；若被占用會中止建構並顯示原因
- **post-create**：分階段初始化（共 5 個階段，詳見下方）
- **post-start**：每次啟動時安裝 pre-commit hooks（含 pre-push）、執行 djlint 模板檢查（`templates/`）、套用 `.env` / `.env.dev`，執行 `migrate`，並以背景程序自動啟動 Django 開發伺服器（`/tmp/django-devserver.log`）
- **rebuild.sh**：以 `docker compose down --remove-orphans --rmi local` 停止容器並清除本機映像，並可透過 `--volumes` 進一步清除 Volume
- **setup-pre-commit.sh**：安裝 / 重新安裝 pre-commit 與 pre-push hooks

---

## 快速開始

```bash
# 1. 以此範本建立新專案目錄並加入你的 Django 程式碼
# （預設 manage.py 位於 src/ 目錄）

# 2. 複製環境變數範例檔
cp .env.example .env

# 3. 以 VS Code 開啟專案
code .

# 4. 執行指令：Dev Containers: Reopen in Container
# 首次建置約需 5-10 分鐘
```

容器就緒後，瀏覽器開啟 [http://localhost:8000](http://localhost:8000) 即可看到 Django 應用程式。

`post-create.sh` 與 `post-start.sh` 會自動讀取 `.env`，並在存在時額外讀取 `.env.dev`。若你要讓 Docker Compose 與腳本都吃到同一份本機設定，請優先使用 `.env`；`.env.dev` 比較適合只給 shell 腳本使用的額外覆寫。

---

## 預期專案目錄結構

```
my-project/
├── .devcontainer/          # DevContainer 設定（此範本）
├── .env                    # 本機環境變數（不納入版本控制）
├── .env.dev                # 選用的額外覆寫檔（不納入版本控制）
├── .env.example            # 環境變數範例
├── src/                    # Django 專案根目錄（預設）
│   ├── manage.py
│   ├── config/
│   │   └── settings.py
│   └── ...
├── pyproject.toml          # 或 requirements.txt
└── ...
```

若你的目錄結構不同，請在 `.env` 中調整以下變數：

```env
DJANGO_PROJECT_DIR=src
DJANGO_SETTINGS_MODULE=config.settings
```

---

## 環境變數（`.env`）

從 `.env.example` 複製後依需求修改，並放成 `.env`：

```env
# Django
DJANGO_SETTINGS_MODULE=config.settings
DJANGO_PROJECT_DIR=src

# PostgreSQL
POSTGRES_DB=app
POSTGRES_USER=app
POSTGRES_PASSWORD=app
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=dev_password
```

腳本載入 `.env` / `.env.dev` 時支援簡單的 `KEY=VALUE` 寫法，允許等號前後空白，並且只會把引號外的行尾註解視為註解；不會執行 shell 指令或進行更複雜的展開。

---

## 相依套件安裝邏輯

`post-create.sh` 依以下順序自動嘗試安裝：

1. `uv pip install -e ".[dev]"`（若 `pyproject.toml` 存在）
2. `uv pip install -r requirements-dev.txt`（若存在）
3. `uv pip install -r requirements.txt`（若存在）

---

## Post-create 初始化階段

| 階段        | 說明                                                                                          |
| ----------- | --------------------------------------------------------------------------------------------- |
| **Stage 0** | 清理 VS Code server extension 快取（防止 SIGPIPE 錯誤累積）                                   |
| **Stage 1** | Python 虛擬環境（`.venv`）建立或重用；重建時保留已快取的套件                                  |
| **Stage 2** | 安裝 Playwright Chromium 瀏覽器（若 venv 內有 playwright）                                    |
| **Stage 3** | 驗證 CLI 工具是否可用：`agent-browser`、`openspec`、`rg`、`fd`、`lsof`、`ast-grep`、`jq`、`fzf`、`gh` |
| **Stage 4** | 執行 `manage.py migrate` 與 `collectstatic`（若找不到 `manage.py` 則略過）                    |

---

## Docker-in-Docker（DinD）

此範本使用 `ghcr.io/devcontainers/features/docker-in-docker:2`，可在 DevContainer 內執行完整的 Docker daemon。

### 使用場景

- 在容器化環境中執行 `docker build` / `docker compose`
- 執行需要啟動 Docker 容器的整合測試

### 技術細節（Debian Trixie 注意事項）

| 項目               | 說明                                                                    |
| ------------------ | ----------------------------------------------------------------------- |
| `moby: false`      | Moby 套件已從 Debian Trixie 移除，必須改用 Docker CE                    |
| `iptables`         | Trixie 無 `iptables-legacy`，改用 `iptables-nft`（Docker 24+ 完整支援） |
| `privileged: true` | `docker-compose.dev.yml` 中設定，允許 dockerd 操控 cgroup 與 namespace  |

---

## 啟用 Celery（選用）

取消 `.devcontainer/docker-compose.dev.yml` 中 `celery` 區塊的注解，並調整 Celery app module 路徑：

```yaml
# celery:
#   command: >
#     bash -c "
#       until [ -f /workspace/.venv/bin/celery ]; do sleep 5; done;
#       cd /workspace/${DJANGO_PROJECT_DIR:-src} && /workspace/.venv/bin/celery -A config worker -l info --pool=solo
#     "
```

---

## 工具腳本

| 腳本                                | 說明                                                                 |
| ----------------------------------- | -------------------------------------------------------------------- |
| `.devcontainer/check-host-ports.sh` | 建構前檢查 `8000`/`5432`/`6379` 是否被占用，衝突時中止並輸出錯誤訊息   |
| `.devcontainer/rebuild.sh`          | 停止容器、清理未使用的 Docker 資源，並可選擇以 `--volumes` 刪除 Volume |
| `.devcontainer/setup-pre-commit.sh` | 安裝或重新安裝 pre-commit / pre-push hooks                           |
| `scripts/sync-ai-skills.sh`         | 重新從 `cookeyholder/using-ai-skills` 同步 `.agent/skills/`          |

常用檢查捷徑：

```bash
# 執行所有 pre-commit checks
make precommit

# 只執行 djlint 模板檢查
make precommit-djlint
```

---

## 容器就緒後的驗證指令

```bash
# 確認 Python / uv 版本
python --version
uv --version

# 確認 Django 版本
/workspace/.venv/bin/python -m django --version

# 確認開發工具
pre-commit --version
openspec --version
agent-browser --help
rg --version
fd --version
lsof -v
ast-grep --version

# 確認 GitHub Copilot CLI
gh copilot --version
gh copilot explain "list files in a directory"
gh copilot suggest "delete all stopped containers"

# 確認 Playwright
/workspace/.venv/bin/python -m playwright --help

# 確認 Docker（DinD）
docker info
docker compose version
```

---

## 注意事項

- **Gitleaks**：透過 pre-commit hook 執行（`pre-commit run gitleaks --all-files`），無需在映像內安裝二進位檔。
- **Fixture 載入**：此範本不包含專案特定的 `loaddata` 呼叫，請在 `post-create.sh` 的 Stage 4 中自行加入。
- **mypy 快取**：`mypy-cache` Volume 跨重建保留，加速型別檢查。
- **ARM64 相容性**：`agent-browser` 在 ARM64 環境會略過自動初始化；若要做瀏覽器自動化，請自行安裝系統 Chromium。
- **`.env.dev`**：可作為額外的 shell-only 覆寫檔，但不建議拿來取代 `.env` 作為 Compose 的主要環境檔。
- **`.env.dev` 不納入版本控制**：`.gitignore` 已設定排除，請勿直接提交含有密碼的 `.env.dev`。

---

## Port 衝突排除

若 `Dev Containers: Reopen in Container` 在建構前失敗，並看到類似以下訊息：

```text
[devcontainer][ERROR] Port 6379 is already in use (Redis).
[devcontainer][ERROR] Build failed because port 6379 is occupied.
```

代表主機已有程序占用該連接埠。可用下列方式排除：

```bash
# 查詢占用中的程序
lsof -nP -iTCP:8000 -sTCP:LISTEN
lsof -nP -iTCP:5432 -sTCP:LISTEN
lsof -nP -iTCP:6379 -sTCP:LISTEN

# 或改用 ss
ss -ltnp | grep -E ':8000|:5432|:6379'
```

釋放占用的連接埠後，再重新執行 `Dev Containers: Reopen in Container`。
