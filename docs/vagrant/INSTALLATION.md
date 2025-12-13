# Vagrant 安裝指南

本文件說明如何在 Windows 環境下安裝並設定 Vagrant + Hyper-V，建立生產環境等級的開發 VM。

---

## 為什麼選擇 Vagrant + Hyper-V？

### 與生產環境一致性
- **完整 Linux 環境**: 100% 真實的 Ubuntu Server 環境
- **Docker Engine 原生運行**: 與生產環境相同的 Docker 部署方式
- **網路行為一致**: 真實的 Linux 網路堆疊，非 WSL2 抽象層
- **系統管理技能可遷移**: 學習真實的 Linux 管理技能

### 與 Docker Desktop 的差異
| 項目 | Vagrant + Docker Engine | Docker Desktop |
|------|-------------------------|----------------|
| 生產環境一致性 | ✅ 100% 一致 | ❌ 高度抽象 |
| 企業授權限制 | ✅ 完全免費 | ⚠️ 商業授權 |
| 學習價值 | ✅ 完整技能 | ❌ 隱藏細節 |
| 系統資源 | ⚠️ 固定分配 | ✅ 動態調整 |
| 啟動速度 | ⚠️ 較慢 | ✅ 快速 |

---

## 前置需求

### 1. Windows 版本需求
- Windows 10 Pro/Enterprise/Education (Build 19041+)
- Windows 11 Pro/Enterprise
- **不支援 Windows Home 版** (Home 版無 Hyper-V 功能)

### 2. 硬體需求
- CPU: 支援虛擬化 (Intel VT-x 或 AMD-V)
- RAM: 最少 8GB (建議 16GB 以上)
- Disk: 至少 120GB 可用空間

### 3. BIOS 設定
確認 BIOS 已啟用虛擬化功能:
- Intel: **VT-x** (Virtualization Technology)
- AMD: **AMD-V** (SVM Mode)

檢查方式:
```powershell
# 以系統管理員身分開啟 PowerShell
systeminfo | findstr /C:"Hyper-V"
```

若顯示 `已偵測到 Hypervisor。不會顯示 Hyper-V 所需的功能。`，代表虛擬化已啟用。

---

## 安裝步驟

### Step 1: 啟用 Hyper-V

以**系統管理員身分**開啟 PowerShell，執行:

```powershell
# 啟用 Hyper-V 功能
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

# 重新啟動電腦
Restart-Computer
```

或透過控制台啟用:
1. 控制台 → 程式集 → 開啟或關閉 Windows 功能
2. 勾選 **Hyper-V** (包含所有子項目)
3. 勾選 **虛擬機器平台**
4. 重新啟動電腦

---

### Step 2: 安裝 Vagrant

#### 方式 1: 使用 Chocolatey (推薦)

```powershell
# 安裝 Vagrant
choco install vagrant -y
```

#### 方式 2: 手動下載安裝

1. 前往 [Vagrant 官網](https://www.vagrantup.com/downloads)
2. 下載 Windows 64-bit 安裝檔
3. 執行安裝程式，使用預設設定
4. 重新啟動終端機

---

### Step 3: 驗證安裝

```bash
# 檢查 Vagrant 版本
vagrant --version
# 預期輸出: Vagrant 2.4.x

# 檢查 Hyper-V 狀態
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
# State 應為 Enabled
```

---

### Step 4: 安裝 Vagrant Plugins

```bash
# hyper 無法使用，重新載入 plugin (簡化 provision 重跑流程)
# vagrant plugin install vagrant-reload

# 驗證 plugin 安裝
vagrant plugin list
```

預期輸出:
```
vagrant-reload (0.0.1, global)
```

---

### Step 5: 配置 Hyper-V 網路

Hyper-V 需要手動建立虛擬交換器:

1. 開啟 **Hyper-V 管理員**
2. 右側選單 → **虛擬交換器管理員**
3. 新增虛擬交換器:
   - 類型: **外部**
   - 名稱: 自訂名稱（`外部虛擬交換器`）
   - 連線類型: 選擇你的實體網路卡
4. 確定

**重要說明**:

- **交換器名稱可以自訂**，不強制使用特定名稱
- **必須在 Vagrantfile 中明確指定**交換器名稱才能自動使用：
  ```ruby
  config.vm.network "public_network",
    bridge: "外部虛擬交換器"  # 必須與 Hyper-V 中的名稱完全一致
  ```
- 如果不指定 `bridge:` 參數，每次 `vagrant up` 時會提示你手動選擇交換器

---

## 驗證完整安裝

建立測試 VM:

```bash
# 建立測試目錄
mkdir vagrant-test && cd vagrant-test

# 初始化 Vagrantfile
vagrant init ubuntu/jammy64

# 啟動 VM
vagrant up --provider=hyperv

# 進入 VM
vagrant ssh

# 在 VM 內檢查
uname -a
# 預期輸出: Linux lab01 5.15.x-xxx-generic #xxx-Ubuntu SMP ...
# 注意: 測試 VM 的 hostname 會是 vagrant，實際專案使用 lab01

# 退出 VM
exit

# 刪除測試 VM
vagrant destroy -f
cd ..
rmdir vagrant-test
```

---

## 常見問題

### Q1: vagrant up 出現網路錯誤？
**A**: 檢查虛擬交換器配置:
```powershell
Get-VMSwitch
```
確保有外部交換器存在。

### Q2: SMB 共享資料夾失敗？
**A**: 啟用 Windows SMB 功能:
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

### Q3: 權限不足錯誤？
**A**: 確保以**系統管理員身分**執行 PowerShell/Terminal。

---

## 下一步

安裝完成後，請參考:
- [CONFIGURATION.md](CONFIGURATION.md) - Vagrantfile 配置說明
- [OPERATIONS.md](OPERATIONS.md) - 日常操作指南
- [PROVISIONING.md](PROVISIONING.md) - 自動化腳本說明

返回主文件: [README.md](../../README.md)
