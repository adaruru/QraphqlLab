# Vagrant 日常操作指南

本文件涵蓋 Vagrant VM 的完整生命週期管理，從建立到刪除的所有常用操作。

---

## 快速參考

```bash
# 啟動 VM
vagrant up

# 進入 VM
vagrant ssh

# 暫停 VM
vagrant suspend

# 關閉 VM
vagrant halt

# 重新啟動 VM
vagrant reload

# 刪除 VM
vagrant destroy

# 查看狀態
vagrant status

# 重新執行 provision
vagrant provision
```

---

## VM 生命週期

### 1. 建立並啟動 VM

```bash
# 首次啟動 (會自動執行 provision)
vagrant up

# 指定 Provider (若有多個虛擬化平台)
vagrant up --provider=hyperv
```

**首次啟動流程**:
```
[1] 下載 Base Box (ubuntu/jammy64) - 若尚未下載
    ↓
[2] 建立 VM (Hyper-V)
    ↓
[3] 配置網路、記憶體、CPU
    ↓
[4] 啟動 VM
    ↓
[5] 執行 Provision 腳本
    ↓
[6] 完成！
```

**預期耗時**:
- 首次: 5-15 分鐘 (含下載 Box)
- 後續: 1-3 分鐘

---

### 2. 連線到 VM

#### 方式 1: Vagrant SSH (推薦)

```bash
vagrant ssh
```

自動登入為 `vagrant` 使用者，具有 sudo 權限。

#### 方式 2: 標準 SSH

```bash
# 使用 vagrant 使用者
ssh vagrant@192.168.56.10

# 使用 admin 使用者
ssh admin@192.168.56.10
# Password: adaruru
```

#### 方式 3: VSCode Remote SSH

1. 安裝 VSCode Extension: **Remote - SSH**
2. `Ctrl+Shift+P` → "Remote-SSH: Connect to Host"
3. 輸入: `vagrant@192.168.56.10`
4. 選擇平台: Linux
5. 開啟專案: `/vagrant`

**優點**:
- 直接在 VSCode 編輯 VM 內檔案
- 終端機整合
- 完整 IDE 功能

---

### 3. 暫停與恢復

#### 暫停 (Suspend)

```bash
vagrant suspend
```

**特性**:
- 保存 VM 記憶體狀態到硬碟
- 下次啟動快速恢復 (10-30 秒)
- 不釋放磁碟空間
- 適合短暫休息

**使用情境**:
- 下班暫停，隔天恢復
- 臨時需要釋放記憶體

#### 恢復

```bash
vagrant resume
```

---

### 4. 關閉 VM

#### 優雅關機 (Halt)

```bash
vagrant halt
```

**特性**:
- 執行標準關機程序 (shutdown)
- 釋放記憶體
- 保留磁碟資料
- 下次啟動需 1-3 分鐘

**使用情境**:
- 長時間不使用 VM
- 需要完全釋放系統資源
- 修改 Vagrantfile 配置前

#### 強制關機 (Force)

```bash
vagrant halt --force
```

**警告**: 可能造成資料損壞，僅在 VM 無回應時使用。

---

### 5. 重新啟動

#### 基本重啟

```bash
vagrant reload
```

等同於:
```bash
vagrant halt
vagrant up
```

#### 重新載入配置並 Provision

```bash
vagrant reload --provision
```

**使用情境**:
- 修改 Vagrantfile 後套用變更
- 重新執行 provision 腳本
- 網路配置變更

---

### 6. 刪除 VM

#### 完全刪除

```bash
vagrant destroy
```

會提示確認:
```
Are you sure you want to destroy the 'default' VM? [y/N]
```

#### 強制刪除 (不詢問)

```bash
vagrant destroy -f
```

**資料遺失警告**:
- ❌ VM 內所有資料會刪除
- ❌ 未 commit 的程式碼會遺失
- ✅ `/vagrant` 同步資料夾內的檔案**不會**刪除 (存在 Windows Host)
- ✅ Vagrantfile 與 provision.sh 保留

**刪除前檢查清單**:
```bash
vagrant ssh

# 檢查是否有未提交的程式碼
cd /vagrant
git status

# 檢查是否有重要資料
ls ~
ls /home/admin

# 備份 Docker Volumes (若需要)
docker volume ls
```

---

## 快照管理

Vagrant 支援 VM 快照，用於版本管理和快速回滾。

### 建立快照

```bash
# 建立快照 (需指定名稱)
vagrant snapshot push

# 建立具名快照
vagrant snapshot save my-snapshot-name
```

**使用情境**:
- 重大變更前備份
- 測試新軟體前保存乾淨狀態
- 開發環境版本管理

### 查看快照

```bash
vagrant snapshot list
```

輸出範例:
```
my-snapshot-name
before-docker-install
clean-state
```

### 恢復快照

```bash
# 恢復最新快照
vagrant snapshot pop

# 恢復指定快照
vagrant snapshot restore my-snapshot-name
```

**注意**: 恢復快照會**覆蓋**當前 VM 狀態。

### 刪除快照

```bash
vagrant snapshot delete my-snapshot-name
```

---

## Provision 管理

### 重新執行 Provision

```bash
# 在執行中的 VM 重跑 provision
vagrant provision

# 啟動時執行 provision
vagrant up --provision

# 重新載入並 provision
vagrant reload --provision
```

### 跳過 Provision

```bash
# 啟動時不執行 provision
vagrant up --no-provision
```

**使用情境**:
- Provision 失敗時，避免重複等待
- 快速重啟 VM

---

## 狀態查詢

### 查看 VM 狀態

```bash
vagrant status
```

可能的狀態:

| 狀態 | 說明 |
|------|------|
| `running` | VM 正在執行 |
| `poweroff` | VM 已關機 |
| `saved` | VM 已暫停 (suspend) |
| `not created` | VM 尚未建立 |

### 查看全域 VM 列表

```bash
vagrant global-status
```

輸出範例:
```
id       name    provider   state   directory
-----------------------------------------------------------------
a1b2c3d  default hyperv     running /d/git/github/QraphqlLab
e4f5g6h  db      hyperv     poweroff /d/projects/another-project
```

### 清理過期 VM 紀錄

```bash
vagrant global-status --prune
```

---

## Box 管理

### 查看已下載的 Box

```bash
vagrant box list
```

輸出範例:
```
ubuntu/jammy64  (hyperv, 20231201.0.0)
ubuntu/focal64  (hyperv, 20230901.0.0)
```

### 更新 Box

```bash
# 檢查是否有新版本
vagrant box outdated

# 更新 Box
vagrant box update
```

**注意**: 更新 Box 不會影響現有 VM，需要 `vagrant destroy` 重建才會使用新版本。

### 刪除舊版 Box

```bash
vagrant box prune
```

---

## 網路操作

### 查看 Port Forwarding

```bash
vagrant port
```

輸出範例:
```
8080 (guest) => 8080 (host)
8081 (guest) => 8081 (host)
3306 (guest) => 3306 (host)
```

### 測試連線

```bash
# 從 Windows 測試 API
curl http://localhost:8080/health

# 測試資料庫連線
mysql -h 127.0.0.1 -P 3306 -u root -p

# 直接存取 VM IP
curl http://192.168.56.10:8080/health
```

---

## Docker 操作 (VM 內)

### 啟動專案

```bash
vagrant ssh
cd /vagrant
docker compose up -d
```

### 查看容器狀態

```bash
docker ps
docker compose ps
```

### 查看日誌

```bash
# 所有服務
docker compose logs -f

# 特定服務
docker compose logs -f api
docker compose logs -f mysql
```

### 停止服務

```bash
# 停止但保留容器
docker compose stop

# 停止並刪除容器
docker compose down

# 停止並刪除 volumes
docker compose down -v
```

---

## 檔案操作

### 從 Windows 複製檔案到 VM

```bash
# 方式 1: 使用同步資料夾
# 直接在 Windows 編輯專案檔案，自動同步到 /vagrant

# 方式 2: SCP
scp local-file.txt vagrant@192.168.56.10:/home/vagrant/

# 方式 3: Vagrant 內建
vagrant upload local-file.txt /home/vagrant/
```

### 從 VM 複製檔案到 Windows

```bash
# 方式 1: 從同步資料夾取得
vagrant ssh
cp /some/file /vagrant/

# 方式 2: SCP
scp vagrant@192.168.56.10:/path/to/file ./

# 方式 3: Vagrant 內建
vagrant download /remote/file ./local/
```

---

## 效能監控

### 在 VM 內監控資源

```bash
vagrant ssh

# 即時系統監控
htop

# 記憶體使用
free -h

# 磁碟使用
df -h

# Docker 資源使用
docker stats
```

### 從 Windows 監控 VM

```powershell
# Hyper-V 管理員
# 視覺化介面查看 CPU/RAM

# PowerShell 查詢
Get-VM -Name "GraphQLLab-DevVM" | Select-Object Name, State, CPUUsage, MemoryAssigned
```

---

## 故障排除

### VM 無法啟動

```bash
# 檢查狀態
vagrant status

# 查看詳細錯誤
vagrant up --debug

# 強制重建
vagrant destroy -f
vagrant up
```

### VM 無法連線

```bash
# 重新載入網路配置
vagrant reload

# 檢查 IP
vagrant ssh
ip addr show
```

### 同步資料夾失敗

```bash
# 重新掛載
vagrant reload

# 檢查 SMB 服務 (Windows)
Get-Service | Where-Object {$_.Name -like "*SMB*"}
```

---

## 最佳實踐

### 1. 定期快照

```bash
# 重要變更前
vagrant snapshot save before-major-change

# 乾淨狀態
vagrant snapshot save clean-state
```

### 2. 不用時關閉 VM

```bash
# 短暫休息
vagrant suspend

# 下班
vagrant halt
```

### 3. 定期更新

```bash
# 每週/每月檢查更新
vagrant box outdated
vagrant box update
```

### 4. 備份 Vagrantfile

```bash
# 納入版本控制
git add Vagrantfile vagrant/
git commit -m "Update VM configuration"
```

---

## 常用工作流程

### 日常開發

```bash
# 上班
vagrant up
vagrant ssh
cd /vagrant
docker compose up -d

# 開發...

# 下班
docker compose down
exit
vagrant halt
```

### 測試部署

```bash
# 建立快照
vagrant snapshot save pre-deploy

# 部署測試
vagrant ssh
cd /vagrant
docker compose up -d

# 若失敗，快速回滾
vagrant snapshot restore pre-deploy
```

### 環境重置

```bash
# 完全重置
vagrant destroy -f
vagrant up

# 恢復到初始狀態
vagrant snapshot restore clean-state
```

---

## 進階操作

### 多 VM 操作

若 Vagrantfile 定義多個 VM:

```bash
# 啟動所有 VM
vagrant up

# 啟動特定 VM
vagrant up app
vagrant up db

# 查看所有 VM 狀態
vagrant status

# 進入特定 VM
vagrant ssh app
vagrant ssh db
```

### 客製化 SSH

```bash
# 查看 SSH 配置
vagrant ssh-config

# 產生 SSH config 用於 IDE
vagrant ssh-config >> ~/.ssh/config
```

---

## 下一步

- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 常見問題與解決方案
- [../docker/ENGINE_BASICS.md](../docker/ENGINE_BASICS.md) - Docker 操作教學

返回: [PROVISIONING.md](PROVISIONING.md)
