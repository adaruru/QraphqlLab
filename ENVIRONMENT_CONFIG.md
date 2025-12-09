# 環境配置說明 (Environment Configuration Guide)

本文件說明如何使用不同的環境配置來啟動 GraphQL Lab 專案。

## 配置方法概述

GraphQL Lab 支援多種環境配置方法，優先順序如下：

1. **環境變數 (Environment Variables)** - 最高優先權，建議用於 Docker 部署
2. **.env 檔案** - Docker Compose 自動載入
3. **YAML 配置檔** - 選用，適合非 Docker 部署

## 支援的環境

| 環境 | .env 檔案 | Docker Compose 覆蓋檔 | MySQL Port | API Port | 用途 |
|------|-----------|---------------------|------------|----------|------|
| Development | `.env` | - | 3306 | 8080 | 本地開發 |
| SIT | `.env.sit` | `docker-compose.sit.yml` | 3307 | 8081 | 系統整合測試 |
| UAT | `.env.uat` | `docker-compose.uat.yml` | 3308 | 8082 | 使用者驗收測試 |
| Production | `.env.prod` | `docker-compose.prod.yml` | 3306 | 8080 | 正式環境 |

## 環境變數說明

### MySQL 配置

| 變數名稱 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `MYSQL_ROOT_PASSWORD` | MySQL root 密碼 | rootpassword | strong_password_123 |
| `MYSQL_DATABASE` | 資料庫名稱 | graphqllab | graphqllab_sit |
| `MYSQL_USER` | MySQL 使用者 | graphqluser | graphqluser_sit |
| `MYSQL_PASSWORD` | MySQL 使用者密碼 | graphqlpass | user_password_123 |
| `MYSQL_PORT` | 對外開放的 Port | 3306 | 3307 |

### API 配置

| 變數名稱 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `API_PORT` | API 服務 Port | 8080 | 8081 |
| `GIN_MODE` | Gin 模式 | debug | release |
| `SERVER_PORT` | 伺服器 Port | 8080 | 8080 |

### 資料庫連線配置 (Go 應用程式使用)

| 變數名稱 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `DB_HOST` | 資料庫主機 | localhost | mysql |
| `DB_PORT` | 資料庫 Port | 3306 | 3306 |
| `DB_USER` | 資料庫使用者 | root | graphqluser |
| `DB_PASSWORD` | 資料庫密碼 | password | user_password |
| `DB_NAME` | 資料庫名稱 | graphqllab | graphqllab_sit |

### 其他配置

| 變數名稱 | 說明 | 預設值 | 範例 |
|---------|------|--------|------|
| `ENVIRONMENT` | 環境名稱 | - | sit, uat, production |
| `LOG_LEVEL` | 日誌等級 | debug | info, warning, error |

## 啟動方式

### 方法一：使用啟動腳本（推薦）

#### Linux / macOS

```bash
# Development
chmod +x scripts/start-dev.sh
./scripts/start-dev.sh

# SIT
chmod +x scripts/start-sit.sh
./scripts/start-sit.sh

# UAT
chmod +x scripts/start-uat.sh
./scripts/start-uat.sh
```

#### Windows

```cmd
REM Development
scripts\start-dev.bat

REM SIT
scripts\start-sit.bat

REM UAT
scripts\start-uat.bat
```

### 方法二：直接使用 Docker Compose

#### Development (使用預設 .env)

```bash
docker compose up -d
```

#### SIT

```bash
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up -d
```

#### UAT

```bash
docker compose -f docker-compose.yml -f docker-compose.uat.yml --env-file .env.uat up -d
```

#### Production

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.prod up -d
```

## 查看服務狀態

```bash
# Development
docker compose ps
docker compose logs -f

# SIT
docker compose -f docker-compose.yml -f docker-compose.sit.yml ps
docker compose -f docker-compose.yml -f docker-compose.sit.yml logs -f

# UAT
docker compose -f docker-compose.yml -f docker-compose.uat.yml ps
docker compose -f docker-compose.yml -f docker-compose.uat.yml logs -f
```

## 停止服務

```bash
# Development
docker compose down

# SIT
docker compose -f docker-compose.yml -f docker-compose.sit.yml down

# UAT
docker compose -f docker-compose.yml -f docker-compose.uat.yml down
```

## 環境變數載入流程

### Docker Compose 載入順序

1. 讀取 `docker-compose.yml` 中的預設值
2. 讀取指定的 `.env` 檔案（透過 `--env-file` 參數）
3. 讀取 override 檔案（如 `docker-compose.sit.yml`）
4. 合併所有配置，後者覆蓋前者

### 示例：SIT 環境啟動流程

```bash
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up -d
```

執行步驟：
1. 載入 `docker-compose.yml` 基礎配置
2. 載入 `.env.sit` 中的環境變數
3. 套用 `docker-compose.sit.yml` 的覆蓋配置
   - 修改 container name 為 `graphqllab-mysql-sit`
   - 修改對外 port 為 3307 (MySQL) 和 8081 (API)
   - 使用獨立的 volume `mysql_data_sit`
4. 啟動服務

## 環境隔離

不同環境可以在同一台機器上同時運行，因為：

1. **不同的 Container 名稱**
   - DEV: `graphqllab-mysql`, `graphqllab-api`
   - SIT: `graphqllab-mysql-sit`, `graphqllab-api-sit`
   - UAT: `graphqllab-mysql-uat`, `graphqllab-api-uat`

2. **不同的 Port 映射**
   - DEV: MySQL 3306, API 8080
   - SIT: MySQL 3307, API 8081
   - UAT: MySQL 3308, API 8082

3. **獨立的 Volume**
   - DEV: `mysql_data`
   - SIT: `mysql_data_sit`
   - UAT: `mysql_data_uat`

4. **獨立的資料庫**
   - DEV: `graphqllab`
   - SIT: `graphqllab_sit`
   - UAT: `graphqllab_uat`

## 測試環境配置

啟動服務後，可以測試配置是否正確：

```bash
# 測試 API Health Check
# DEV
curl http://localhost:8080/health

# SIT
curl http://localhost:8081/health

# UAT
curl http://localhost:8082/health

# 預期回應
{"status":"healthy","database":"connected"}
```

## 資料庫連線測試

```bash
# DEV
mysql -h 127.0.0.1 -P 3306 -u graphqluser -p

# SIT
mysql -h 127.0.0.1 -P 3307 -u graphqluser_sit -p

# UAT
mysql -h 127.0.0.1 -P 3308 -u graphqluser_uat -p
```

## 環境變數寫入方法示例

### 在 Go 程式中讀取環境變數

```go
import "os"

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

// 使用範例
dbHost := getEnv("DB_HOST", "localhost")
dbPort := getEnv("DB_PORT", "3306")
```

### 在 Docker Compose 中使用環境變數

```yaml
services:
  api:
    environment:
      DB_HOST: ${DB_HOST:-mysql}
      DB_PORT: ${DB_PORT:-3306}
      DB_NAME: ${DB_NAME:-graphqllab}
```

語法說明：
- `${變數名}` - 直接使用環境變數
- `${變數名:-預設值}` - 使用環境變數，若不存在則使用預設值

## 安全性建議

### Development 環境
- ✅ 可以使用簡單密碼
- ✅ 可以啟用 debug mode
- ✅ .env 可以加入版控（僅限開發用途）

### SIT/UAT 環境
- ⚠️ 使用中等強度密碼
- ⚠️ 考慮啟用 release mode
- ⚠️ .env 檔案不要加入版控

### Production 環境
- ❌ 絕對不要使用預設密碼
- ✅ 必須使用強密碼（至少 16 字元，包含大小寫、數字、特殊字元）
- ✅ 啟用 release mode
- ✅ .env.prod 絕對不可加入版控
- ✅ 考慮使用 Docker secrets 或 Kubernetes secrets
- ✅ 定期更換密碼
- ✅ 限制網路存取

## 故障排除

### 環境變數沒有生效

檢查順序：
1. 確認使用了正確的 `.env` 檔案
2. 確認 docker compose 命令有加 `--env-file` 參數
3. 檢查環境變數格式（不要有空格）
4. 重新啟動服務

```bash
docker compose down
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up -d
```

### Port 衝突

如果遇到 port 被占用：
1. 檢查是否有其他環境正在運行
2. 修改 `.env` 檔案中的 port 設定
3. 或修改 `docker-compose.*.yml` 中的 port 映射

### 查看實際載入的環境變數

```bash
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit config
```

此命令會顯示合併後的完整配置。

## 檔案結構

```
QraphqlLab/
├── .env                          # Development 環境變數
├── .env.sit                      # SIT 環境變數
├── .env.uat                      # UAT 環境變數
├── .env.prod                     # Production 環境變數
├── config.example.yaml           # 配置範例（YAML 格式）
├── docker-compose.yml            # 基礎 Docker Compose 配置
├── docker-compose.sit.yml        # SIT 環境覆蓋配置
├── docker-compose.uat.yml        # UAT 環境覆蓋配置
├── docker-compose.prod.yml       # Production 環境覆蓋配置
└── scripts/
    ├── start-dev.sh              # Linux/macOS 開發環境啟動腳本
    ├── start-sit.sh              # Linux/macOS SIT 啟動腳本
    ├── start-uat.sh              # Linux/macOS UAT 啟動腳本
    ├── start-dev.bat             # Windows 開發環境啟動腳本
    ├── start-sit.bat             # Windows SIT 啟動腳本
    └── start-uat.bat             # Windows UAT 啟動腳本
```

## 總結

- 使用 `.env` 檔案管理不同環境的配置
- 使用 docker-compose override 檔案隔離環境
- 使用啟動腳本簡化操作流程
- 環境變數優先於 YAML 配置檔
- 不同環境使用不同的 port 和 volume 避免衝突
- Production 環境必須特別注意安全性
