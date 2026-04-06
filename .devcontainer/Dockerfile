# DevContainer 基礎映像：DevContainers 官方 Python 映像
FROM mcr.microsoft.com/devcontainers/python:1-3.13

# 某些基底映像殘留過期 Yarn APT source，會導致 apt-get update 因 GPG 驗章失敗而中斷
RUN rm -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarnpkg.list

# 建立工作目錄
RUN mkdir -p /workspace
WORKDIR /workspace

# 安裝 WeasyPrint 依賴、Node.js 24（NodeSource）與常用開發工具
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    build-essential \
    pkg-config \
    libcairo2-dev \
    libpango1.0-dev \
    libgdk-pixbuf-2.0-dev \
    libffi-dev \
    shared-mime-info \
    ca-certificates \
    curl \
    gnupg \
    ripgrep \
    fd-find \
    fzf \
    jq \
    yq \
    gh \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get -y install --no-install-recommends nodejs \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# 注意：gitleaks 由 .pre-commit-config.yaml 的 hook 管理，無需在映像內另外下載二進位檔

# 安裝 uv（必須在使用 uv 之前安裝），並確保 uv 在 PATH 中
RUN pip install uv \
    && mkdir -p /etc/profile.d \
    && echo 'export PATH="/usr/local/py-utils/bin:$PATH"' > /etc/profile.d/devcontainer-path.sh \
    && echo 'export PATH="/root/.local/bin:$PATH"' >> /etc/profile.d/devcontainer-path.sh \
    && echo 'export PATH="/home/vscode/.local/bin:$PATH"' >> /etc/profile.d/devcontainer-path.sh \
    && chmod +x /etc/profile.d/devcontainer-path.sh

# 安裝 pip-audit 和 pre-commit
RUN uv pip install --system pip-audit pre-commit

# 安裝視覺相似度比較所需的 Python 套件
RUN uv pip install --system imagehash scipy

# 安裝 Node CLI 工具（瀏覽器自動化 / 程式碼搜尋 / OpenSpec）
ARG AST_GREP_CLI_VERSION=0.42.0
ARG OPENSPEC_VERSION=1.2.0
ARG AGENT_BROWSER_VERSION=0.24.0
RUN npm config set prefix /usr/local \
    && npm install -g \
    @ast-grep/cli@${AST_GREP_CLI_VERSION} \
    @fission-ai/openspec@${OPENSPEC_VERSION} \
    agent-browser@${AGENT_BROWSER_VERSION} \
    && npm cache clean --force

# 確保非 root 使用者擁有正確的權限，並設定快取目錄
ARG USERNAME=vscode
RUN chown -R ${USERNAME} /workspace \
    && mkdir -p /home/${USERNAME}/.cache/uv \
    && mkdir -p /home/${USERNAME}/.cache/ms-playwright \
    && mkdir -p /vscode/vscode-server/extensionsCache \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.cache \
    && chown -R ${USERNAME}:${USERNAME} /vscode/vscode-server 2>/dev/null || true \
    && mkdir -p /workspace/.venv \
    && chown -R ${USERNAME}:${USERNAME} /workspace/.venv
