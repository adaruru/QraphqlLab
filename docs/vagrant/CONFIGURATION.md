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
config.vm.box = "generic/ubuntu2204"
config.vm.box_version = ">= 0"
```

- **為什麼使用 Generic 系列**:
  - **重要**: `ubuntu/` 系列 box 只支援 VirtualBox
  - **Hyper-V 必須使用 `generic/` 系列**
  - `generic/ubuntu2204` 專為多 provider 設計（VirtualBox、Hyper-V、VMware）
  - 不能直接 vagrant up --provider=hyperv
  - 必須先 vagrant box add generic/ubuntu2204
  - 且下載時會問你， Please review the list and choose the provider you will be working with.
  - 下載時間約 1 分半，看個人網速

### 主機名稱

```ruby
config.vm.hostname = "lab01"
```

進入 VM 後的 Shell 提示符會顯示此名稱:
```bash
vagrant@lab01:~$
```

---

## 網路配置

### Public Network (Bridged Network)

```ruby
config.vm.network "public_network",
  bridge: "外部虛擬交換器",
  ip: "192.168.11.110"
```

**用途**:
- VM 直接連接到實體網路（透過 Hyper-V 虛擬交換器）
- 取得與 Host 同網段的 IP 位址
- 模擬真實生產環境的網路架構
- 區域網路內的其他設備可直接存取 VM

**存取方式**:
```bash
# 從 Windows 或區域網路內任何設備存取
curl http://192.168.11.110:8080/health

# SSH 連線
ssh vagrant@192.168.11.110
ssh lab01@192.168.11.110  # 密碼: adaruru
ssh root@192.168.11.110   # 密碼: adaruru
```

**重要**: 交換器名稱必須與 Hyper-V 中建立的外部交換器名稱完全一致。

## 同步資料夾

### 預設配置（生產環境模擬）

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

**專案採用生產環境模擬方案**:
- **已停用**同步資料夾，完全模擬生產環境
- 不使用 Windows 與 VM 之間的共享資料夾
- 所有檔案需透過 Git Clone 或 SCP 傳輸至 VM

**為什麼停用同步資料夾**:
- 完全隔離，與生產環境一致
- 檔案 I/O 效能最佳（原生 Linux 檔案系統）
- 練習真實部署流程
- 避免 Hyper-V SMB 協定的效能問題

### 如果需要啟用同步資料夾

開發時若需要即時同步，可修改為:

```ruby
# 啟用同步資料夾
config.vm.synced_folder ".", "/vagrant", disabled: false
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
  h.vmname = "lab01"
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
| `vmname` | lab01 | Hyper-V 管理員中顯示的 VM 名稱 |
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
    app.vm.hostname = "lab01-app"
    app.vm.network "public_network",
      bridge: "外部虛擬交換器",
      ip: "192.168.11.111"
    app.vm.provider "hyperv" do |h|
      h.vmname = "lab01-app"
      h.memory = 2048
    end
  end

  # Database Server
  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/jammy64"
    db.vm.hostname = "lab01-db"
    db.vm.network "public_network",
      bridge: "外部虛擬交換器",
      ip: "192.168.11.112"
    db.vm.provider "hyperv" do |h|
      h.vmname = "lab01-db"
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
# 專案使用: Public Network (生產環境模擬)
config.vm.network "public_network",
  bridge: "外部虛擬交換器",
  ip: "192.168.11.110"

# 替代方案: Private Network (開發用，較快速)
# config.vm.network "private_network", ip: "192.168.56.10"
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
