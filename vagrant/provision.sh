#!/bin/bash
set -e

echo "=========================================="
echo "GraphQL Lab VM Provision Script"
echo "=========================================="

# 更新系統
echo "[1/8] 更新系統套件..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

# 安裝基礎工具
echo "[2/8] 安裝基礎工具..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release \
    tree

# 安裝 Docker Engine
echo "[3/8] 安裝 Docker Engine..."
# 移除舊版本
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# 新增 Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 新增 Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安裝 Docker
sudo apt-get update -qq
sudo apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 啟動 Docker 服務
echo "[4/8] 啟動 Docker 服務..."
sudo systemctl enable docker
sudo systemctl start docker

# 設定使用者權限
echo "[5/8] 設定使用者權限..."
# 新增 vagrant 使用者到 docker group (免 sudo)
sudo usermod -aG docker vagrant

# 建立 lab01 使用者
echo "[6/8] 建立 lab01 使用者..."
if ! id "lab01" &>/dev/null; then
    sudo useradd -m -s /bin/bash -G sudo,docker lab01
    echo "lab01:adaruru" | sudo chpasswd
    echo "lab01 使用者已建立 (密碼: adaruru)"
else
    echo "lab01 使用者已存在"
    sudo usermod -aG docker lab01
fi

# 設定 root 密碼
echo "[7/8] 設定 root 密碼..."
echo "root:adaruru" | sudo chpasswd
echo "root 密碼已設定 (密碼: adaruru)"

# 驗證安裝
echo "[8/8] 驗證安裝..."
echo "Docker 版本:"
docker --version
docker compose version

echo ""
echo "=========================================="
echo "Provision 完成！"
echo "=========================================="
echo ""
echo "使用者資訊:"
echo "  - vagrant (sudo 權限, docker group)"
echo "  - lab01   (sudo 權限, docker group, 密碼: adaruru)"
echo "  - root    (密碼: adaruru)"
echo ""
echo "已安裝工具:"
echo "  - Docker Engine: $(docker --version | awk '{print $3}')"
echo "  - Docker Compose: $(docker compose version | awk '{print $4}')"
echo "  - Git: $(git --version | awk '{print $3}')"
echo ""
echo "下一步:"
echo "  1. 登出後重新登入以套用 docker group 權限"
echo "  2. 執行: docker run hello-world"
echo "  3. Clone 專案並啟動服務"
echo "=========================================="

# 顯示磁碟資訊
echo ""
echo "磁碟資訊:"
df -h | grep -E "Filesystem|/dev/sd"

echo ""
echo "系統資訊:"
echo "  - OS: $(lsb_release -d | cut -f2)"
echo "  - Kernel: $(uname -r)"
echo "  - RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo "  - CPU: $(nproc) cores"
