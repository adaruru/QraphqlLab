# Vagrantfile 配置詳解

本文件詳細說明專案中 `Vagrantfile` 的各項配置，幫助你理解和客製化開發環境。

---

## 檔案位置

```
QraphqlLab/
├── Vagrantfile           # VM 配置主檔
└── vagrant/
    └── provision.sh      # 自動化安裝腳本
```

---

## 基礎配置

### Box 選擇

```ruby
config.vm.box = "ubuntu/jammy64"
config.vm.box_version = ">= 0"
```

- **Box**: Ubuntu 22.04 LTS (Jammy Jellyfish)
- **為什麼選擇 Jammy**:
  - LTS 版本，穩定且長期支援至 2027 年
  - Docker 官方完整支援
  - 與主流雲端平台 (AWS, Azure, GCP) 預設映像一致
  - 預裝 systemd，支援標準服務管理

### 主機名稱

```ruby
config.vm.hostname = "graphqllab-dev"
```

進入 VM 後的 Shell 提示符會顯示此名稱:
```bash
vagrant@graphqllab-dev:~$
```

---

## 網路配置

### 1. Private Network (Host-Only)

```ruby
config.vm.network "private_network", ip: "192.168.56.10"
```

**用途**:
- Windows Host 與 VM 之間的專用網路
- 可直接透過 IP 存取 VM 服務
- 不會暴露到外部網路

**存取方式**:
```bash
# 從 Windows 直接存取
curl http://192.168.56.10:8080/health

# SSH 連線 (替代 vagrant ssh)
ssh vagrant@192.168.56.10
```

### 2. Port Forwarding

```ruby
config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
config.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"
config.vm.network "forwarded_port", guest: 3306, host: 3306, host_ip: "127.0.0.1"
```

| Guest Port | Host Port | 用途 |
|------------|-----------|------|
| 8080 | 8080 | Go API (DEV 環境) |
| 8081 | 8081 | Go API (SIT 環境) |
| 3306 | 3306 | MySQL 資料庫 |
| 2375 | 2375 | Docker Daemon API (可選) |

**安全性設定**:
- `host_ip: "127.0.0.1"`: 只允許 localhost 存取，不暴露到區域網路
- 若需區域網路存取，改為: `host_ip: "0.0.0.0"`

**Port 衝突處理**:
若 Windows 已佔用 Port 3306 (例如已安裝 MySQL)，可修改為:
```ruby
config.vm.network "forwarded_port", guest: 3306, host: 3307
```
連線時改用: `localhost:3307`

---

## 同步資料夾

### 預設配置

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: false
```

**運作方式**:
- Windows 專案目錄 `D:\git\github\QraphqlLab`
- ↔ 對應 VM 內 `/vagrant` 目錄
- 雙向即時同步

**效能考量**:
- Hyper-V 使用 SMB 協定，檔案 I/O 相對較慢
- 適合小型檔案 (配置檔、程式碼)
- 不適合大量小檔案 (node_modules, vendor)

### 生產環境模擬方案

若要完全模擬生產環境 (不使用共享資料夾):

```ruby
# 停用同步資料夾
config.vm.synced_folder ".", "/vagrant", disabled: true
```

改用 Git Clone:
```bash
vagrant ssh
git clone https://github.com/your-repo/QraphqlLab.git
cd QraphqlLab
docker compose up -d
```

**優點**:
- 完全隔離，與生產環境一致
- 檔案 I/O 效能最佳 (原生 Linux 檔案系統)
- 練習真實部署流程

**缺點**:
- IDE 無法直接編輯 VM 內檔案 (需使用 VSCode Remote SSH)

---

## Provider 配置

### Hyper-V (主要配置)

```ruby
config.vm.provider "hyperv" do |h|
  h.vmname = "GraphQLLab-DevVM"
  h.memory = 2048
  h.cpus = 2
  h.enable_virtualization_extensions = true
  h.linked_clone = true
  h.auto_start_action = "Nothing"
  h.auto_stop_action = "ShutDown"
end
```

**參數說明**:

| 參數 | 值 | 說明 |
|------|-----|------|
| `vmname` | GraphQLLab-DevVM | Hyper-V 管理員中顯示的 VM 名稱 |
| `memory` | 2048 | RAM 配置 (MB)，建議最少 2GB |
| `cpus` | 2 | CPU 核心數 |
| `enable_virtualization_extensions` | true | 啟用巢狀虛擬化 (Docker 需要) |
| `linked_clone` | true | 差異磁碟，節省空間 |
| `auto_start_action` | Nothing | Windows 開機時不自動啟動 VM |
| `auto_stop_action` | ShutDown | Windows 關機時優雅關閉 VM |

**記憶體調整建議**:
```ruby
# 開發環境: 最少 2GB
h.memory = 2048

# 多容器環境: 4GB
h.memory = 4096

# 效能測試: 8GB
h.memory = 8192
```

### VirtualBox (備用)

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.name = "GraphQLLab-DevVM"
  vb.memory = 2048
  vb.cpus = 2
end
```

**切換 Provider**:
```bash
# 使用 Hyper-V (預設)
vagrant up

# 強制使用 VirtualBox
vagrant up --provider=virtualbox
```

---

## 磁碟配置

### Disksize Plugin

```ruby
if Vagrant.has_plugin?("vagrant-disksize")
  config.disksize.size = "100GB"
else
  puts "警告: vagrant-disksize plugin 未安裝"
end
```

**為什麼需要 100GB**:
- Base OS: ~5GB
- Docker Images: 20-30GB (多環境、多版本)
- Volumes: 10-20GB (資料庫資料)
- Logs: 5-10GB
- 預留空間: 30GB

**安裝 Plugin**:
```bash
vagrant plugin install vagrant-disksize
```

**查看實際使用**:
```bash
vagrant ssh
df -h
```

---

## Provision 配置

```ruby
config.vm.provision "shell", path: "vagrant/provision.sh"
```

**執行時機**:
- 首次 `vagrant up` 時自動執行
- 手動執行: `vagrant provision`
- VM 重建時執行: `vagrant reload --provision`

**Provision 腳本功能**:
1. 更新系統
2. 安裝 Docker Engine
3. 建立使用者 (admin)
4. 設定權限

詳細說明請參考: [PROVISIONING.md](PROVISIONING.md)

---

## SSH 配置

```ruby
config.ssh.forward_agent = true
config.ssh.insert_key = true
```

| 參數 | 說明 |
|------|------|
| `forward_agent` | 轉送 SSH Agent，可在 VM 內使用 Host 的 SSH Key |
| `insert_key` | 自動產生安全的 SSH Key，取代不安全的預設 Key |

**實際應用**:
```bash
# 在 VM 內可直接 Git Clone 私有 Repo (使用 Host 的 SSH Key)
vagrant ssh
git clone git@github.com:your-private/repo.git
```

---

## 啟動訊息

```ruby
config.vm.post_up_message = <<-MESSAGE
  VM 已啟動！
  IP: 192.168.56.10
  ...
MESSAGE
```

**客製化訊息**:
可根據專案需求調整提示內容，例如新增:
- 預設登入帳號密碼
- 重要 URL
- 下一步操作指引

---

## 客製化範例

### 多 VM 配置 (進階)

模擬微服務架構:

```ruby
Vagrant.configure("2") do |config|
  # App Server
  config.vm.define "app" do |app|
    app.vm.box = "ubuntu/jammy64"
    app.vm.network "private_network", ip: "192.168.56.10"
    app.vm.provider "hyperv" do |h|
      h.vmname = "GraphQLLab-App"
      h.memory = 2048
    end
  end

  # Database Server
  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.provider "hyperv" do |h|
      h.vmname = "GraphQLLab-DB"
      h.memory = 4096
    end
  end
end
```

啟動方式:
```bash
vagrant up app      # 只啟動 App Server
vagrant up db       # 只啟動 DB Server
vagrant up          # 啟動全部
```

---

## 效能優化建議

### 1. 記憶體配置
```ruby
# 根據 Host 實體記憶體調整
# Host 8GB  -> VM 2GB
# Host 16GB -> VM 4GB
# Host 32GB -> VM 8GB
h.memory = 4096
```

### 2. 網路模式選擇
```ruby
# 開發環境: Private Network (快速)
config.vm.network "private_network", ip: "192.168.56.10"

# 生產模擬: Public Network (真實)
config.vm.network "public_network", bridge: "Ethernet"
```

### 3. 同步資料夾優化
```ruby
# 排除大型目錄
config.vm.synced_folder ".", "/vagrant",
  rsync__exclude: [".git/", "node_modules/", "vendor/"]
```

---

## 下一步

- [PROVISIONING.md](PROVISIONING.md) - 理解自動化安裝流程
- [OPERATIONS.md](OPERATIONS.md) - 學習日常操作指令
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 常見問題排除

返回: [INSTALLATION.md](INSTALLATION.md)
