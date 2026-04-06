# DevContainer 基礎映像：官方 Python slim 映像（Debian Trixie）
# 選擇 slim 而非 mcr.microsoft.com/devcontainers/python 以取得更輕量、可控的基礎
FROM python:3.13-slim-trixie

# 某些基底映像殘留過期 Yarn APT source，會導致 apt-get update 因 GPG 驗章失敗而中斷
RUN rm -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarnpkg.list

# --- 建立非 root vscode 使用者並授予 passwordless sudo 權限 ---
# python:3.13-slim-trixie 不含內建 vscode 使用者，需手動建立（UID 1000）
# 這與 mcr.microsoft.com/devcontainers/python 的慣例一致
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    git \
    sudo \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

# 建立工作目錄
RUN mkdir -p /workspace
WORKDIR /workspace

# 安裝 WeasyPrint 依賴、Node.js 24（NodeSource）與常用開發工具
#
# 關於 Docker-in-Docker 與 iptables（Debian Trixie 注意事項）：
#   - Trixie 採用 iptables-nft 作為預設（無 iptables-legacy）
#   - Docker 24+ 支援 iptables-nft，因此 DinD 可正常運作
#   - devcontainer DinD feature 安裝的 iptables 套件在 Trixie 指向 iptables-nft
#   - 若 iptables-legacy 不存在，feature 會跳過切換步驟並繼續使用 iptables-nft
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
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
    iptables \
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

# 安裝 uv 並設定 PATH
RUN pip install uv \
    && mkdir -p /etc/profile.d \
    && echo 'export PATH="/root/.local/bin:$PATH"' > /etc/profile.d/devcontainer-path.sh \
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
RUN chown -R ${USERNAME} /workspace \
    && mkdir -p /home/${USERNAME}/.cache/uv \
    && mkdir -p /home/${USERNAME}/.cache/ms-playwright \
    && mkdir -p /vscode/vscode-server/extensionsCache \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.cache \
    && chown -R ${USERNAME}:${USERNAME} /vscode/vscode-server 2>/dev/null || true \
    && mkdir -p /workspace/.venv \
    && chown -R ${USERNAME}:${USERNAME} /workspace/.venv
