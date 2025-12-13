# Vagrant 常見問題排除

本文件收集使用 Vagrant + Hyper-V 時常見的問題與解決方案。

---

## 安裝相關問題

### Q1: 無法啟用 Hyper-V

**錯誤訊息**:
```
Hyper-V cannot be installed: The processor does not have required virtualization capabilities.
```

**原因**:
1. CPU 不支援虛擬化
2. BIOS 未啟用虛擬化功能
3. Windows 版本不支援 (Home 版)

**解決方案**:

#### 檢查 CPU 支援

```powershell
# 檢查虛擬化支援
systeminfo | findstr /C:"Hyper-V"
```

若顯示:
```
Hyper-V 需求: 已偵測到 Hypervisor。不會顯示 Hyper-V 所需的功能。
```
代表虛擬化已啟用，可略過下一步。

#### 啟用 BIOS 虛擬化

1. 重新啟動電腦，進入 BIOS (通常按 F2/F10/DEL)
2. 尋找虛擬化選項:
   - Intel: **Intel VT-x** 或 **Virtualization Technology**
   - AMD: **AMD-V** 或 **SVM Mode**
3. 設為 **Enabled**
4. 儲存並重新啟動

#### Windows 版本限制

Hyper-V **不支援** Windows Home 版，需升級至:
- Windows 10/11 Pro
- Windows 10/11 Enterprise
- Windows 10/11 Education

---

### Q2: Hyper-V 與 VirtualBox 衝突

**錯誤訊息**:
```
VirtualBox can't operate in VMX root mode.
```

**原因**: Hyper-V 與 VirtualBox 無法同時運行。

**解決方案**:

#### 方案 1: 停用 Hyper-V (使用 VirtualBox)

```powershell
# 以系統管理員身分執行
bcdedit /set hypervisorlaunchtype off
Restart-Computer
```

恢復 Hyper-V:
```powershell
bcdedit /set hypervisorlaunchtype auto
Restart-Computer
```

#### 方案 2: 使用 Vagrant 指定 Provider

```bash
# 使用 VirtualBox
vagrant up --provider=virtualbox

# 使用 Hyper-V
vagrant up --provider=hyperv
```

---

### Q3: vagrant-disksize Plugin 安裝失敗

**錯誤訊息**:
```
ERROR: Failed to build gem native extension.
```

**解決方案**:

```bash
# Windows 需先安裝 MSYS2 Development Tools
# 方式 1: 重新安裝 Vagrant (勾選 Development Tools)

# 方式 2: 手動安裝
vagrant plugin install vagrant-disksize --plugin-clean-sources --plugin-source https://rubygems.org
```

若持續失敗，可暫時不使用此 plugin，手動擴充磁碟:
```ruby
# Vagrantfile 移除或註解此段
# config.disksize.size = "100GB"
```

---

## 啟動相關問題

### Q4: vagrant up 卡在 "Waiting for machine to boot"

**可能原因**:
1. 網路配置錯誤
2. Hyper-V 虛擬交換器問題
3. SMB 共享資料夾失敗

**解決方案**:

#### Step 1: 檢查虛擬交換器

```powershell
Get-VMSwitch
```

應該要有至少一個 External Switch。若沒有:

1. 開啟 Hyper-V 管理員
2. 右側 → 虛擬交換器管理員
3. 新增外部虛擬交換器
4. 連線至實體網路卡

#### Step 2: 檢查防火牆

```powershell
# 允許 Hyper-V
New-NetFirewallRule -DisplayName "Hyper-V" -Direction Inbound -Action Allow
```

#### Step 3: 重建 VM

```bash
vagrant destroy -f
vagrant up --provider=hyperv
```

---

### Q5: SMB 共享資料夾掛載失敗

**錯誤訊息**:
```
Failed to mount folders in Linux guest. This is usually because the "vboxsf" file system is not available.
```

**原因**: Windows SMB 服務未啟用或版本不相容。

**解決方案**:

#### 啟用 SMB 1.0 (若必要)

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
```

**安全警告**: SMB 1.0 有安全漏洞，建議使用 SMB 2.0+。

#### 檢查 SMB 服務

```powershell
Get-Service | Where-Object {$_.Name -like "*SMB*"}
```

確保 `LanmanServer` 和 `LanmanWorkstation` 處於 Running 狀態。

#### 停用共享資料夾 (替代方案)

```ruby
# Vagrantfile
config.vm.synced_folder ".", "/vagrant", disabled: true
```

改用 Git Clone 在 VM 內操作:
```bash
vagrant ssh
git clone https://github.com/your-repo/QraphqlLab.git
cd QraphqlLab
```

---

### Q6: 權限不足錯誤

**錯誤訊息**:
```
Access denied. You must be running with administrator privileges.
```

**解決方案**:

以**系統管理員身分**開啟 PowerShell 或 Terminal:

1. 右鍵點選 Terminal/PowerShell
2. 選擇「以系統管理員身分執行」
3. 執行 `vagrant up`

或設定 Terminal 預設以管理員身分啟動:
1. Terminal → 設定
2. 預設設定檔 → 進階
3. 勾選「以系統管理員身分執行」

---

## 網路相關問題

### Q7: 無法存取 VM 服務 (Port Forwarding 失效)

**症狀**: `curl http://localhost:8080` 無回應。

**解決方案**:

#### Step 1: 確認 VM 內服務已啟動

```bash
vagrant ssh

# 檢查 Docker 容器
docker ps

# 檢查 Port 監聽
sudo netstat -tulpn | grep 8080
```

#### Step 2: 檢查 Vagrant Port Forwarding

```bash
vagrant port
```

應顯示:
```
8080 (guest) => 8080 (host)
```

#### Step 3: 檢查 Windows 防火牆

```powershell
# 允許 Port 8080
New-NetFirewallRule -DisplayName "Vagrant-8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

#### Step 4: 使用 Private Network IP

```bash
# 改用 VM IP
curl http://192.168.56.10:8080
```

---

### Q8: Private Network IP 無法連線

**錯誤**: `curl: (7) Failed to connect to 192.168.56.10 port 8080`

**解決方案**:

#### 檢查 VM IP

```bash
vagrant ssh
ip addr show
```

確認是否有 `192.168.56.10` 這個 IP。

#### 重新載入網路配置

```bash
vagrant reload
```

#### 手動配置網路 (VM 內)

```bash
vagrant ssh

# 編輯網路配置
sudo vim /etc/netplan/50-vagrant.yaml
```

新增:
```yaml
network:
  version: 2
  ethernets:
    eth1:
      addresses:
        - 192.168.56.10/24
```

套用:
```bash
sudo netplan apply
```

---

## Provision 相關問題

### Q9: Provision 腳本執行失敗

**錯誤訊息**:
```
The SSH command responded with a non-zero exit status.
```

**解決方案**:

#### 查看詳細錯誤

```bash
vagrant provision --debug
```

#### 手動執行 Provision

```bash
vagrant ssh

# 手動執行腳本
sudo bash /vagrant/vagrant/provision.sh
```

觀察具體錯誤訊息。

#### 常見 Provision 錯誤

**Docker 安裝失敗**:
```bash
# 檢查網路連線
ping google.com

# 手動安裝 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

**GPG Key 下載失敗**:
```bash
# 網路問題，重試
sudo apt-get update
```

---

### Q10: Docker 安裝後無法使用

**錯誤**: `permission denied while trying to connect to the Docker daemon socket`

**原因**: 使用者未加入 `docker` group。

**解決方案**:

```bash
vagrant ssh

# 檢查群組
groups

# 手動加入 docker group
sudo usermod -aG docker $USER

# 重新登入
exit
vagrant ssh

# 驗證
docker ps
```

---

## 效能相關問題

### Q11: VM 啟動非常慢

**可能原因**:
1. 磁碟 I/O 慢
2. 記憶體不足
3. 防毒軟體干擾

**解決方案**:

#### 增加 VM 記憶體

```ruby
# Vagrantfile
config.vm.provider "hyperv" do |h|
  h.memory = 4096  # 增加到 4GB
end
```

#### 排除防毒掃描

將以下目錄加入防毒軟體排除清單:
- `D:\git\github\QraphqlLab`
- `C:\Users\YourName\.vagrant.d`
- Hyper-V VM 儲存路徑

#### 使用 SSD

確保專案與 VM 存放於 SSD，非 HDD。

---

### Q12: 同步資料夾效能差

**症狀**: 檔案修改後，VM 內延遲數秒才更新。

**解決方案**:

#### 方案 1: 停用即時同步

```ruby
# Vagrantfile
config.vm.synced_folder ".", "/vagrant",
  type: "smb",
  smb_username: ENV['USERNAME'],
  smb_password: ENV['PASSWORD']
```

#### 方案 2: 使用 rsync (單向同步)

```ruby
config.vm.synced_folder ".", "/vagrant",
  type: "rsync",
  rsync__exclude: [".git/", "node_modules/"]
```

手動同步:
```bash
vagrant rsync
```

#### 方案 3: 不使用同步資料夾

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

改用 Git + VSCode Remote SSH。

---

## 快照相關問題

### Q13: 快照建立失敗

**錯誤**: `The machine does not support snapshots.`

**原因**: 部分 Hyper-V 配置不支援快照。

**解決方案**:

```ruby
# Vagrantfile - 確保不使用 Linked Clone
config.vm.provider "hyperv" do |h|
  h.linked_clone = false  # 停用差異磁碟
end
```

重建 VM:
```bash
vagrant destroy -f
vagrant up
```

---

### Q14: 快照恢復後網路失效

**症狀**: 恢復快照後無法連線到 VM。

**解決方案**:

```bash
# 恢復快照後重新載入網路
vagrant snapshot restore my-snapshot
vagrant reload
```

---

## 其他問題

### Q15: Vagrant 指令無回應

**症狀**: 執行 `vagrant` 指令後卡住。

**解決方案**:

#### 清理過期 VM

```bash
vagrant global-status --prune
```

#### 刪除鎖定檔案

```bash
# 移除 Vagrant 鎖定檔案
rm -rf .vagrant/
```

#### 重新啟動 Hyper-V 服務

```powershell
Restart-Service vmms
```

---

### Q16: Box 下載失敗或速度慢

**解決方案**:

#### 手動下載 Box

1. 前往 [Vagrant Cloud](https://app.vagrantup.com/boxes/search)
2. 搜尋 `ubuntu/jammy64`
3. 下載對應 Hyper-V Provider 的 Box
4. 手動新增:

```bash
vagrant box add ubuntu/jammy64 /path/to/downloaded.box
```

#### 使用鏡像站 (中國地區)

```ruby
# Vagrantfile
config.vm.box_url = "https://mirrors.tuna.tsinghua.edu.cn/ubuntu-cloud-images/jammy/current/jammy-server-cloudimg-amd64-vagrant.box"
```

---

## 除錯技巧

### 啟用詳細輸出

```bash
# 所有 Vagrant 指令都可加上 --debug
vagrant up --debug 2>&1 | tee vagrant.log
```

### 檢查 Vagrant 狀態

```bash
vagrant version
vagrant plugin list
vagrant box list
vagrant global-status
```

### 檢查 Hyper-V 狀態

```powershell
Get-VM
Get-VMSwitch
Get-Service vmms
```

### 重置 Vagrant 環境

```bash
# 完全清理
vagrant destroy -f
rm -rf .vagrant/
vagrant box remove ubuntu/jammy64
vagrant box add ubuntu/jammy64
vagrant up
```

---

## 取得協助

若以上方案無法解決問題:

1. **查看 Vagrant 官方文件**: https://www.vagrantup.com/docs
2. **Vagrant GitHub Issues**: https://github.com/hashicorp/vagrant/issues
3. **Hyper-V 文件**: https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/
4. **專案 Issue Tracker**: 提交問題至本專案 GitHub Issues

提交問題時請附上:
- `vagrant --version`
- `vagrant global-status`
- `vagrant up --debug` 輸出
- Vagrantfile 內容
- Windows 版本與 Build 號

---

## 返回文件

- [OPERATIONS.md](OPERATIONS.md) - 日常操作指南
- [INSTALLATION.md](INSTALLATION.md) - 安裝指南
- [README.md](../../README.md) - 專案首頁
