# Provision 自動化腳本說明

本文件詳細說明 `vagrant/provision.sh` 的運作邏輯，以及如何客製化自動化安裝流程。

---

## Provision 是什麼？

**Provision** 是 Vagrant 的自動化配置機制，用於在 VM 建立後自動執行初始化任務。

### 執行時機

```bash
# 首次建立 VM 時自動執行
vagrant up

# 手動重新執行
vagrant provision

# 重新啟動並執行 provision
vagrant reload --provision

# 刪除重建 (會執行 provision)
vagrant destroy -f && vagrant up
```

---

## 腳本架構

### 完整流程

```bash
[1/8] 更新系統套件
    ↓
[2/8] 安裝基礎工具 (git, curl, vim, htop...)
    ↓
[3/8] 安裝 Docker Engine
    ↓
[4/8] 啟動 Docker 服務
    ↓
[5/8] 設定使用者權限 (docker group)
    ↓
[6/8] 建立 admin 使用者
    ↓
[7/8] 設定 root 密碼
    ↓
[8/8] 驗證安裝
```

---

## 逐步解析

### [1/8] 系統更新

```bash
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq
```

**參數說明**:
- `-qq`: Quiet mode，減少輸出訊息
- `DEBIAN_FRONTEND=noninteractive`: 避免互動式提示 (全自動)
- `-y`: 自動回答 Yes

**為什麼需要**:
- 確保系統套件為最新版本
- 修補已知安全漏洞
- 避免相依性衝突

---

### [2/8] 安裝基礎工具

```bash
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
```

**工具用途**:

| 工具 | 用途 | 實際應用 |
|------|------|----------|
| `curl` | HTTP 請求 | 下載檔案、測試 API |
| `wget` | 下載工具 | 下載大型檔案 |
| `git` | 版本控制 | Clone 專案、版本管理 |
| `vim` | 文字編輯器 | 編輯配置檔 |
| `htop` | 系統監控 | 即時查看 CPU/RAM |
| `net-tools` | 網路工具 | netstat, ifconfig |
| `ca-certificates` | SSL 憑證 | HTTPS 連線 |
| `gnupg` | GPG 加密 | 驗證套件簽章 |
| `lsb-release` | 系統資訊 | 取得 Ubuntu 版本 |
| `tree` | 目錄樹狀顯示 | 查看專案結構 |

**客製化範例**:
若需要 Python 開發環境，新增:
```bash
sudo apt-get install -y -qq \
    python3 \
    python3-pip \
    python3-venv
```

---

### [3/8] 安裝 Docker Engine

#### Step 1: 移除舊版本

```bash
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
```

- `2>/dev/null`: 隱藏錯誤訊息
- `|| true`: 即使失敗也繼續執行 (首次安裝時這些套件不存在)

#### Step 2: 新增 Docker GPG Key

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

**安全性說明**:
- GPG Key 用於驗證 Docker 套件的真實性
- 防止中間人攻擊 (Man-in-the-Middle)
- 確保下載的是官方正版套件

#### Step 3: 新增 Docker Repository

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**動態參數**:
- `$(dpkg --print-architecture)`: 自動偵測 CPU 架構 (amd64/arm64)
- `$(lsb_release -cs)`: 自動偵測 Ubuntu 代號 (jammy)

#### Step 4: 安裝 Docker

```bash
sudo apt-get update -qq
sudo apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
```

**套件說明**:

| 套件 | 說明 |
|------|------|
| `docker-ce` | Docker Engine (Community Edition) |
| `docker-ce-cli` | Docker 命令列工具 |
| `containerd.io` | 容器執行時 (Runtime) |
| `docker-buildx-plugin` | 多平台建置工具 |
| `docker-compose-plugin` | Docker Compose V2 |

**版本確認**:
```bash
docker --version
# Docker version 24.0.x, build xxxxx

docker compose version
# Docker Compose version v2.23.x
```

---

### [4/8] 啟動 Docker 服務

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

**systemd 指令說明**:
- `enable`: 開機自動啟動 Docker
- `start`: 立即啟動 Docker 服務

**驗證服務狀態**:
```bash
sudo systemctl status docker
# Active: active (running) since ...
```

---

### [5/8] 設定使用者權限

```bash
sudo usermod -aG docker vagrant
```

**為什麼需要**:
預設只有 root 可執行 Docker 指令:
```bash
# 需要 sudo (不便)
sudo docker ps

# 加入 docker group 後 (方便)
docker ps
```

**安全性考量**:
- `docker` group 成員等同 root 權限
- 只新增信任的使用者
- 生產環境建議使用 rootless Docker

**生效方式**:
```bash
# 方式 1: 重新登入
exit
vagrant ssh

# 方式 2: 切換群組
newgrp docker
```

---

### [6/8] 建立 admin 使用者

```bash
if ! id "admin" &>/dev/null; then
    sudo useradd -m -s /bin/bash -G sudo,docker admin
    echo "admin:adaruru" | sudo chpasswd
fi
```

**參數說明**:
- `-m`: 建立 home 目錄 (`/home/admin`)
- `-s /bin/bash`: 設定 Shell
- `-G sudo,docker`: 加入群組 (sudo 權限 + docker 權限)
- `chpasswd`: 批次設定密碼

**使用情境**:
```bash
# 從 Windows SSH 連線
ssh admin@192.168.56.10
# Password: adaruru

# 在 VM 內切換使用者
su - admin
```

**安全性警告**:
生產環境應使用 SSH Key 認證，禁用密碼登入:
```bash
# 僅供開發環境使用！
# 生產環境請使用: ssh-keygen + authorized_keys
```

---

### [7/8] 設定 root 密碼

```bash
echo "root:adaruru" | sudo chpasswd
```

**為什麼設定 root 密碼**:
- Ubuntu Cloud Image 預設 root 無密碼
- 方便系統維護與故障排除
- 開發環境使用 (生產環境應禁用 root 登入)

**切換到 root**:
```bash
vagrant ssh
sudo su -
# Password: adaruru
```

---

### [8/8] 驗證安裝

```bash
docker --version
docker compose version
df -h
free -h
```

**檢查項目**:
1. ✅ Docker 版本正確
2. ✅ Docker Compose 可用
3. ✅ 磁碟空間充足 (100GB)
4. ✅ 記憶體配置正確 (2GB)

---

## 客製化 Provision

### 新增額外軟體

在 `provision.sh` 中新增:

```bash
# [9/8] 安裝 Node.js
echo "[9/8] 安裝 Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version
npm --version
```

### 新增環境變數

```bash
# 設定 Go 環境變數
echo 'export GOPATH=$HOME/go' >> /home/vagrant/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin' >> /home/vagrant/.bashrc
```

### 新增 Docker 配置

```bash
# 設定 Docker daemon.json
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl restart docker
```

---

## 多階段 Provision

Vagrant 支援多個 Provision 腳本:

```ruby
# Vagrantfile
config.vm.provision "shell", path: "vagrant/provision-base.sh"
config.vm.provision "shell", path: "vagrant/provision-docker.sh"
config.vm.provision "shell", path: "vagrant/provision-app.sh"
```

**優點**:
- 模組化管理
- 可選擇性執行特定階段
- 重用性高

**執行特定 Provision**:
```bash
vagrant provision --provision-with shell
```

---

## 條件式 Provision

根據環境變數決定是否執行:

```ruby
# Vagrantfile
if ENV['INSTALL_MONITORING'] == 'true'
  config.vm.provision "shell", path: "vagrant/provision-monitoring.sh"
end
```

```bash
# 啟動時控制
INSTALL_MONITORING=true vagrant up
```

---

## Provision 最佳實踐

### 1. 冪等性 (Idempotent)
確保多次執行不會出錯:

```bash
# ❌ 不好的寫法
useradd admin

# ✅ 好的寫法
if ! id "admin" &>/dev/null; then
    useradd admin
fi
```

### 2. 錯誤處理
```bash
# 啟用嚴格模式
set -e  # 遇到錯誤立即停止
set -u  # 使用未定義變數時報錯
set -o pipefail  # Pipeline 任一指令失敗即失敗
```

### 3. 進度提示
```bash
echo "[1/5] 執行中..."
echo "[2/5] 執行中..."
```

### 4. 驗證步驟
```bash
# 安裝後驗證
if ! command -v docker &> /dev/null; then
    echo "錯誤: Docker 安裝失敗"
    exit 1
fi
```

---

## 除錯 Provision

### 查看 Provision 輸出

```bash
# 詳細輸出
vagrant up --debug

# 只重跑 provision，查看輸出
vagrant provision
```

### 手動驗證

```bash
vagrant ssh

# 檢查 provision 是否成功
docker --version
id admin
groups vagrant
```

### 重置 Provision

```bash
# 完全重置 VM
vagrant destroy -f
vagrant up
```

---

## 進階應用

### Ansible Provision (推薦生產環境)

```ruby
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbook.yml"
end
```

**優點**:
- 宣告式配置
- 可重用於實際伺服器
- 豐富的模組生態

### Docker Provision

```ruby
config.vm.provision "docker" do |d|
  d.pull_images "mysql:8.0"
  d.pull_images "golang:1.21"
end
```

---

## 下一步

- [OPERATIONS.md](OPERATIONS.md) - 學習 VM 日常操作
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Provision 失敗排除

返回: [CONFIGURATION.md](CONFIGURATION.md)
