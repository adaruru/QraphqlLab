# Task 0003 系列完成總結

## 任務概覽

### 0003-1: 修正 Dockerfile.mysql ✅
**目標：** 移除硬編碼的環境變數，改由 docker-compose.yml 管理

**完成項目：**
- ✅ 移除 `ENV MYSQL_DATABASE` 和 `ENV MYSQL_ROOT_PASSWORD`
- ✅ 所有敏感資訊移至 docker-compose.yml 的 environment 區塊
- ✅ 密碼和使用者資訊由 .env 檔案統一管理

### 0003-2: 多環境配置系統 ✅
**目標：** 建立 SIT、UAT 環境配置與啟動腳本

**完成項目：**
- ✅ 建立 `.env.sit`, `.env.uat`, `.env.prod` 環境配置檔
- ✅ 建立 `docker-compose.sit.yml`, `docker-compose.uat.yml`, `docker-compose.prod.yml` 覆蓋檔
- ✅ 建立 Linux/macOS 啟動腳本（`start-dev.sh`, `start-sit.sh`, `start-uat.sh`）
- ✅ 建立 Windows 啟動腳本（`start-dev.bat`, `start-sit.bat`, `start-uat.bat`）
- ✅ 環境隔離機制（不同 port、container name、volume）
- ✅ 完整的環境變數載入流程

### 0003-3: Config vs Env 深度說明 ✅
**目標：** 深入說明為什麼要分開使用配置檔案和環境變數

**完成項目：**
- ✅ 建立詳細的說明文件（`docs/CONFIG_VS_ENV.md`）
- ✅ 建立配置決策樹（`docs/CONFIG_DECISION_TREE.md`）
- ✅ 建立詳細註解的配置範例（`config.detailed.example.yaml`）
- ✅ 更新 `config.example.yaml` 加入完整說明

## 建立的檔案清單

### 環境配置檔案
1. `.env.sit` - SIT 環境變數
2. `.env.uat` - UAT 環境變數
3. `.env.prod` - Production 環境變數

### Docker Compose 檔案
4. `docker-compose.sit.yml` - SIT 環境覆蓋配置
5. `docker-compose.uat.yml` - UAT 環境覆蓋配置
6. `docker-compose.prod.yml` - Production 環境覆蓋配置

### 啟動腳本（Linux/macOS）
7. `scripts/start-dev.sh` - 開發環境啟動
8. `scripts/start-sit.sh` - SIT 環境啟動
9. `scripts/start-uat.sh` - UAT 環境啟動

### 啟動腳本（Windows）
10. `scripts/start-dev.bat` - 開發環境啟動
11. `scripts/start-sit.bat` - SIT 環境啟動
12. `scripts/start-uat.bat` - UAT 環境啟動

### 配置範例與說明
13. `config.detailed.example.yaml` - 詳細註解的配置範例
14. `config.example.yaml` - 更新並加入完整說明

### 文件
15. `ENVIRONMENT_CONFIG.md` - 環境配置完整指南
16. `QUICK_START_ENVIRONMENTS.md` - 快速啟動參考
17. `docs/CONFIG_VS_ENV.md` - Config vs Env 深度解析（10000+ 字）
18. `docs/CONFIG_DECISION_TREE.md` - 配置決策樹與實例分析
19. `docs/TASK_0003_SUMMARY.md` - 本文件

### 更新的檔案
20. `infra/Dockerfile.mysql` - 移除硬編碼環境變數
21. `.gitignore` - 排除 .env.prod 等敏感檔案

## 核心概念說明

### 1. Config vs Env 分離原則

#### 使用環境變數 (.env)
```bash
# 敏感資訊
DB_PASSWORD=secret

# 環境特定值
DB_HOST=mysql-sit.internal
DB_PORT=3307
DB_NAME=graphqllab_sit

# 運行模式
GIN_MODE=release
LOG_LEVEL=info
```

#### 使用配置檔案 (config.yaml)
```yaml
# 業務邏輯設定
database:
  max_connections: 25
  timeout: 30s
  charset: utf8mb4

# 功能開關
features:
  enable_graphql: true
  enable_rest: true

# 速率限制
rate_limit:
  requests_per_minute: 100
```

### 2. 為什麼要分開？

| 原因 | 說明 |
|------|------|
| **安全性** | 敏感資訊不會被提交到 Git |
| **靈活性** | 輕鬆切換環境而無需修改代碼 |
| **12-Factor App** | 符合業界最佳實踐 |
| **容器化友善** | Docker/K8s 原生支援環境變數 |
| **職責分離** | 開發者管理 config，DevOps 管理 env |

### 3. 配置優先順序

```
環境變數 > .env 檔案 > config.yaml > 程式碼預設值
```

## 環境隔離架構

### 同時運行多環境

| 環境 | Container Name | MySQL Port | API Port | Database | Volume |
|------|---------------|------------|----------|----------|--------|
| DEV | graphqllab-api | 3306 | 8080 | graphqllab | mysql_data |
| SIT | graphqllab-api-sit | 3307 | 8081 | graphqllab_sit | mysql_data_sit |
| UAT | graphqllab-api-uat | 3308 | 8082 | graphqllab_uat | mysql_data_uat |

### 啟動方式

```bash
# 可以同時啟動所有環境
./scripts/start-dev.sh  # Port: 3306, 8080
./scripts/start-sit.sh  # Port: 3307, 8081
./scripts/start-uat.sh  # Port: 3308, 8082

# 驗證
curl http://localhost:8080/health  # DEV
curl http://localhost:8081/health  # SIT
curl http://localhost:8082/health  # UAT
```

## 環境變數載入流程

```
啟動腳本 (start-sit.sh)
    ↓
檢查 .env.sit 存在
    ↓
載入環境變數
    MYSQL_DATABASE=graphqllab_sit
    API_PORT=8081
    ↓
執行 docker compose
    -f docker-compose.yml        (基礎配置)
    -f docker-compose.sit.yml    (SIT 覆蓋)
    --env-file .env.sit          (環境變數)
    ↓
Docker Compose 合併配置
    ↓
建立 Container
    Name: graphqllab-mysql-sit
    Port: 3307:3306
    Env: MYSQL_DATABASE=graphqllab_sit
    ↓
應用程式讀取環境變數
    os.Getenv("DB_NAME") → "graphqllab_sit"
```

## 配置決策樹

```
有一個配置值需要設定
    ↓
是敏感資訊？（密碼、金鑰）
    ├─ 是 → 環境變數 (.env)
    └─ 否 → 繼續
        ↓
    會因環境不同？
        ├─ 是 → 環境變數 (.env)
        └─ 否 → 繼續
            ↓
        是業務邏輯設定？
            ├─ 是 → 配置檔案 (config.yaml)
            └─ 否 → 環境變數 (.env)
```

## 實際應用範例

### 範例 1：資料庫連線

```go
// 從環境變數讀取（環境特定 + 敏感）
host := os.Getenv("DB_HOST")         // mysql-sit.internal
password := os.Getenv("DB_PASSWORD") // secret123

// 從配置檔案讀取（固定設定）
cfg := loadConfig()
maxConn := cfg.Database.MaxConnections  // 25
charset := cfg.Database.Charset         // utf8mb4

// 建立連線
db := createConnection(host, password, maxConn, charset)
```

### 範例 2：功能開關

```yaml
# config.yaml - 業務邏輯
features:
  enable_graphql: true
  enable_rest: true
```

```bash
# .env - 可以覆蓋
ENABLE_GRAPHQL=false  # 暫時關閉 GraphQL
```

## 文件導讀

### 快速上手
- 閱讀 `QUICK_START_ENVIRONMENTS.md` - 5 分鐘快速啟動

### 深入理解
- 閱讀 `docs/CONFIG_VS_ENV.md` - 理解為什麼要分開（30 分鐘）
- 閱讀 `docs/CONFIG_DECISION_TREE.md` - 學會如何決策（15 分鐘）

### 實作參考
- 查看 `config.detailed.example.yaml` - 詳細註解範例
- 查看 `ENVIRONMENT_CONFIG.md` - 完整配置指南

## 最佳實踐總結

### ✅ DO（推薦）

1. **敏感資訊永遠用環境變數**
   ```bash
   DB_PASSWORD=secret  # ✅
   JWT_SECRET=key123   # ✅
   ```

2. **環境特定值用環境變數**
   ```bash
   DB_HOST=mysql-sit.internal  # ✅
   API_PORT=8081               # ✅
   ```

3. **業務邏輯用配置檔案**
   ```yaml
   rate_limit:
     requests_per_minute: 100  # ✅
   ```

4. **提供清楚的預設值**
   ```go
   dbHost := getEnv("DB_HOST", "localhost")  // ✅
   ```

5. **寫清楚的註解**
   ```yaml
   # 連線池大小 - 所有環境使用相同值
   max_connections: 25  # ✅
   ```

### ❌ DON'T（避免）

1. **不要把密碼寫在配置檔案**
   ```yaml
   password: secret123  # ❌ 危險！
   ```

2. **不要把 .env.prod 提交到 Git**
   ```bash
   # .gitignore
   .env.prod  # ✅ 必須排除
   ```

3. **不要混亂地使用兩種方式**
   - 建立清楚的使用規則
   - 團隊達成共識

## 成果展示

### 啟動 SIT 環境

```bash
$ ./scripts/start-sit.sh

=========================================
Starting GraphQL Lab - SIT Environment
=========================================

Environment: SIT (System Integration Test)
Using config file: .env.sit

Configuration:
  MySQL Database: graphqllab_sit
  MySQL Port: 3307 (external), 3306 (internal)
  API Port: 8081 (external), 8080 (internal)

Starting services...
✓ Services started successfully!

Available endpoints:
  - API: http://localhost:8081
  - Health: http://localhost:8081/health
  - MySQL: localhost:3307
```

### 驗證健康狀態

```bash
$ curl http://localhost:8081/health
{"status":"healthy","database":"connected"}
```

## 下一步

現在環境配置已完成，可以繼續進行：

1. ✅ Task 0001 - Go 專案初始化
2. ✅ Task 0002 - MySQL 資料庫設計
3. ✅ Task 0003 - Docker Compose 環境配置
4. ✅ Task 0003-1 - Dockerfile 最佳化
5. ✅ Task 0003-2 - 多環境配置
6. ✅ Task 0003-3 - Config vs Env 說明
7. ⏭️ Task 0004 - Repository Pattern 實作

## 總結

透過這三個子任務，我們建立了：

1. **安全的配置管理** - 敏感資訊不會洩漏
2. **靈活的環境切換** - 一鍵啟動不同環境
3. **清楚的配置架構** - 團隊容易理解和維護
4. **完整的文件系統** - 新人快速上手

這些基礎建設將大幅提升後續開發效率和系統安全性！
