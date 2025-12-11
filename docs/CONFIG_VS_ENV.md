# Config vs Env：配置管理深度解析

## 為什麼要分開管理？

在軟體開發中，配置管理有兩種主要方式：

1. **配置檔案 (Config Files)** - YAML, JSON, TOML 等
2. **環境變數 (Environment Variables)** - .env 檔案或系統環境變數

本文件深入說明為什麼需要兩種方式，以及如何正確使用。

## 核心原則：The Twelve-Factor App

根據 [12-Factor App](https://12factor.net/) 原則第三條：

> **III. Config: Store config in the environment**
>
> 配置應該嚴格與代碼分離，並存儲在環境變數中。

### 為什麼這很重要？

```
❌ 錯誤做法：將密碼寫在配置檔案中
config.yaml:
  database:
    password: "my_secret_password"  # 危險！會被提交到 Git

✅ 正確做法：使用環境變數
.env:
  DB_PASSWORD=my_secret_password   # 不提交到 Git
```

## 配置類型分類

### 1. 敏感資訊 (Sensitive Data)
**必須使用環境變數**

| 類型 | 範例 | 原因 |
|------|------|------|
| 密碼 | `DB_PASSWORD`, `API_KEY` | 安全性 |
| 金鑰 | `JWT_SECRET`, `ENCRYPTION_KEY` | 安全性 |
| Token | `GITHUB_TOKEN`, `OAUTH_SECRET` | 安全性 |
| 連線字串 | 包含密碼的完整 DSN | 安全性 |

**範例：**
```bash
# .env (不提交到 Git)
DB_PASSWORD=super_secret_password_123
JWT_SECRET=my-jwt-secret-key-2024
API_KEY=sk-1234567890abcdef
```

### 2. 環境特定值 (Environment-Specific Values)
**應該使用環境變數**

| 類型 | 範例 | 原因 |
|------|------|------|
| 主機名稱 | `DB_HOST`, `REDIS_HOST` | 每個環境不同 |
| Port | `API_PORT`, `DB_PORT` | 避免衝突 |
| 資料庫名稱 | `DB_NAME` | 隔離環境 |
| 運行模式 | `GIN_MODE`, `NODE_ENV` | 環境差異 |

**範例：**
```bash
# .env.sit
DB_HOST=mysql-sit.example.com
DB_NAME=graphqllab_sit
API_PORT=8081

# .env.uat
DB_HOST=mysql-uat.example.com
DB_NAME=graphqllab_uat
API_PORT=8082
```

### 3. 應用程式設定 (Application Settings)
**可以使用配置檔案**

| 類型 | 範例 | 原因 |
|------|------|------|
| 業務邏輯設定 | 最大重試次數、超時時間 | 不常變動 |
| 功能開關 | Feature flags | 程式邏輯 |
| 預設值 | 分頁大小、快取時間 | 程式邏輯 |
| 格式設定 | 日誌格式、日期格式 | 程式邏輯 |

**範例：**
```yaml
# config.yaml
application:
  max_retry: 3
  timeout: 30s
  page_size: 20
  cache_ttl: 3600

logging:
  format: json
  level: info
```

## 實際應用場景

### 場景 1：資料庫連線

#### 方法 A：全部使用環境變數 ✅ 推薦

```bash
# .env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=secret123
DB_NAME=myapp
DB_CHARSET=utf8mb4
DB_MAX_CONNECTIONS=25
DB_IDLE_CONNECTIONS=5
```

**優點：**
- ✅ 完全符合 12-Factor App
- ✅ 容易在不同環境切換
- ✅ 密碼不會洩漏

**缺點：**
- ❌ 環境變數太多，管理較複雜
- ❌ 不適合複雜的巢狀結構

#### 方法 B：混合使用 ✅ 實務推薦

```yaml
# config.yaml (提交到 Git)
database:
  charset: utf8mb4              # 固定設定
  max_connections: 25           # 預設值
  idle_connections: 5           # 預設值
  timeout: 30s                  # 預設值

# 敏感資訊和環境特定值從環境變數讀取
# host: ${DB_HOST}
# port: ${DB_PORT}
# user: ${DB_USER}
# password: ${DB_PASSWORD}
# name: ${DB_NAME}
```

```bash
# .env (不提交到 Git)
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=secret123
DB_NAME=myapp
```

**Go 程式碼實現：**
```go
type DatabaseConfig struct {
    Host            string        // 從環境變數讀取
    Port            int           // 從環境變數讀取
    User            string        // 從環境變數讀取
    Password        string        // 從環境變數讀取
    Name            string        // 從環境變數讀取
    Charset         string        // 從 config 檔案讀取
    MaxConnections  int           // 從 config 檔案讀取
    IdleConnections int           // 從 config 檔案讀取
    Timeout         time.Duration // 從 config 檔案讀取
}

func LoadConfig() *DatabaseConfig {
    // 從 config.yaml 載入固定設定
    cfg := loadYAMLConfig()

    // 從環境變數覆蓋敏感資訊
    cfg.Host = getEnv("DB_HOST", cfg.Host)
    cfg.Port = getEnvInt("DB_PORT", cfg.Port)
    cfg.User = getEnv("DB_USER", cfg.User)
    cfg.Password = getEnv("DB_PASSWORD", "")
    cfg.Name = getEnv("DB_NAME", cfg.Name)

    return cfg
}
```

**優點：**
- ✅ 敏感資訊在環境變數中
- ✅ 固定設定在配置檔案中
- ✅ 兩者優點結合
- ✅ 易於管理和維護

### 場景 2：多環境部署

```
專案結構：
├── config/
│   ├── default.yaml          # 預設配置（提交到 Git）
│   ├── development.yaml      # 開發環境覆蓋（提交到 Git）
│   └── production.yaml       # 正式環境覆蓋（提交到 Git）
├── .env.example              # 範例（提交到 Git）
├── .env                      # 實際配置（不提交）
├── .env.sit                  # SIT 配置（不提交）
├── .env.uat                  # UAT 配置（不提交）
└── .env.prod                 # 正式配置（不提交）
```

## 配置優先順序

```
最高優先 → 最低優先

1. 系統環境變數
2. .env 檔案
3. 環境特定配置檔 (config.production.yaml)
4. 預設配置檔 (config.default.yaml)
5. 程式碼內建預設值
```

**實例：決定 DB_HOST 的值**

```go
// 1. 程式碼內建預設值
dbHost := "localhost"

// 2. 從 config.default.yaml 讀取
if cfg.Database.Host != "" {
    dbHost = cfg.Database.Host  // 假設為 "db.example.com"
}

// 3. 從 config.production.yaml 讀取（若存在）
if prodCfg.Database.Host != "" {
    dbHost = prodCfg.Database.Host  // 假設為 "prod-db.example.com"
}

// 4. 從 .env 檔案讀取
if envHost := os.Getenv("DB_HOST"); envHost != "" {
    dbHost = envHost  // 假設為 "mysql"
}

// 最終 dbHost = "mysql"（環境變數優先）
```

## 為什麼要這樣分？

### 1. 安全性 (Security)

```yaml
# ❌ 錯誤：敏感資訊在配置檔案中
# config.yaml (會被提交到 Git)
database:
  password: "my_secret_password"  # 洩漏！
  api_key: "sk-1234567890"        # 洩漏！

# ✅ 正確：敏感資訊在環境變數中
# .env (不會被提交到 Git)
DB_PASSWORD=my_secret_password
API_KEY=sk-1234567890

# config.yaml (可以安全提交)
database:
  charset: utf8mb4
  timeout: 30s
```

### 2. 靈活性 (Flexibility)

**情境：需要在三個環境部署**

```bash
# 方法 A：使用配置檔案（需要維護三個檔案）
config.dev.yaml      # 開發環境
config.sit.yaml      # SIT 環境
config.uat.yaml      # UAT 環境

# 方法 B：使用環境變數（一個配置檔案 + 三個 .env）
config.yaml          # 共用配置（一份）
.env.dev             # 開發環境變數
.env.sit             # SIT 環境變數
.env.uat             # UAT 環境變數
```

使用環境變數後，只需要：
```bash
# 切換環境超簡單
docker compose --env-file .env.sit up    # 啟動 SIT
docker compose --env-file .env.uat up    # 啟動 UAT
```

### 3. 符合容器化最佳實踐

**Docker 建議的方式：**

```dockerfile
# ❌ 不好：將配置打包進 image
COPY config.production.yaml /app/config.yaml
# 問題：每個環境需要不同的 image

# ✅ 好：透過環境變數注入配置
ENV DB_HOST=mysql
ENV DB_PORT=3306
# 優點：同一個 image 可以用於所有環境
```

**Docker Compose 範例：**

```yaml
# docker-compose.yml
services:
  api:
    image: myapp:latest      # 同一個 image
    environment:
      DB_HOST: ${DB_HOST}    # 從 .env 注入
      DB_PORT: ${DB_PORT}
      DB_NAME: ${DB_NAME}
```

### 4. 職責分離 (Separation of Concerns)

| 配置類型 | 管理者 | 存放位置 | 變更頻率 |
|---------|--------|----------|---------|
| 業務邏輯設定 | 開發人員 | config.yaml | 低（隨版本更新） |
| 環境配置 | DevOps | .env | 中（環境建置時設定） |
| 敏感資訊 | 安全團隊 | Secrets 管理系統 | 低（定期輪換） |

**範例：**

```yaml
# config.yaml - 開發人員負責
application:
  name: "GraphQL Lab"
  version: "1.0.0"
  features:
    enable_graphql: true
    enable_rest: true
  rate_limit:
    requests_per_minute: 100
    burst: 20
```

```bash
# .env - DevOps 負責
DB_HOST=prod-mysql-cluster.internal
DB_PORT=3306
REDIS_HOST=prod-redis.internal
LOG_LEVEL=warning
```

```bash
# Kubernetes Secret - 安全團隊負責
DB_PASSWORD=<encrypted>
JWT_SECRET=<encrypted>
API_KEY=<encrypted>
```

## GraphQL Lab 專案的實作

### 當前架構

```
配置檔案 (config.yaml):
├── 資料庫連線參數（charset, max_connections）
├── 伺服器設定（timeout, 預設 port）
├── 日誌格式設定
└── 業務邏輯設定

環境變數 (.env):
├── DB_HOST, DB_PORT           # 環境特定
├── DB_USER, DB_PASSWORD       # 敏感資訊
├── DB_NAME                    # 環境特定
├── API_PORT                   # 環境特定
├── GIN_MODE                   # 環境特定
└── LOG_LEVEL                  # 環境特定
```

### 讀取順序示意圖

```
應用程式啟動
    │
    ├─> 1. 載入 config.yaml 預設值
    │       charset: utf8mb4
    │       max_connections: 25
    │       timeout: 30s
    │
    ├─> 2. 讀取環境變數
    │       DB_HOST=mysql
    │       DB_PORT=3306
    │       DB_PASSWORD=secret
    │
    ├─> 3. 合併配置
    │       {
    │         host: "mysql",          // 來自環境變數
    │         port: 3306,             // 來自環境變數
    │         password: "secret",     // 來自環境變數
    │         charset: "utf8mb4",     // 來自 config.yaml
    │         max_connections: 25,    // 來自 config.yaml
    │         timeout: 30s            // 來自 config.yaml
    │       }
    │
    └─> 4. 建立資料庫連線
```

## 實作建議

### 建議 1：明確區分配置類型

```go
// config/config.go

// ApplicationConfig - 固定的應用程式設定（從 YAML 讀取）
type ApplicationConfig struct {
    Name        string
    Version     string
    Features    FeatureFlags
    RateLimit   RateLimitConfig
}

// EnvironmentConfig - 環境特定配置（從環境變數讀取）
type EnvironmentConfig struct {
    DBHost      string
    DBPort      int
    DBName      string
    APIPort     int
    GinMode     string
    LogLevel    string
}

// SecretsConfig - 敏感資訊（從環境變數或 Secrets 管理讀取）
type SecretsConfig struct {
    DBPassword  string
    JWTSecret   string
    APIKey      string
}

// 合併所有配置
type Config struct {
    App     ApplicationConfig
    Env     EnvironmentConfig
    Secrets SecretsConfig
}
```

### 建議 2：提供清楚的預設值

```go
func DefaultConfig() *Config {
    return &Config{
        App: ApplicationConfig{
            Name:    "GraphQL Lab",
            Version: "1.0.0",
        },
        Env: EnvironmentConfig{
            DBHost:   "localhost",  // 開發環境預設
            DBPort:   3306,
            DBName:   "graphqllab",
            APIPort:  8080,
            GinMode:  "debug",
            LogLevel: "debug",
        },
        // Secrets 沒有預設值，必須提供
    }
}
```

### 建議 3：驗證必要配置

```go
func (c *Config) Validate() error {
    // 敏感資訊必須設定
    if c.Secrets.DBPassword == "" {
        return errors.New("DB_PASSWORD is required")
    }

    // 環境特定值檢查
    if c.Env.DBHost == "" {
        return errors.New("DB_HOST is required")
    }

    return nil
}
```

## 常見問題

### Q1: 為什麼不全部用環境變數？

**答：** 雖然符合 12-Factor App，但有實務問題：

```bash
# 環境變數太多，難以管理
export APP_NAME="GraphQL Lab"
export APP_VERSION="1.0.0"
export FEATURE_GRAPHQL_ENABLED=true
export FEATURE_REST_ENABLED=true
export RATE_LIMIT_RPM=100
export RATE_LIMIT_BURST=20
export LOG_FORMAT=json
export LOG_TIMESTAMP_FORMAT="2006-01-02 15:04:05"
export CACHE_TTL=3600
export SESSION_TIMEOUT=1800
export MAX_UPLOAD_SIZE=10485760
# ... 100+ 個環境變數？
```

**建議：** 只將「必須因環境而異」或「敏感」的配置放環境變數。

### Q2: 為什麼不全部用配置檔案？

**答：** 不符合容器化和安全最佳實踐：

```yaml
# ❌ 問題：密碼寫在配置檔案中
# config.production.yaml
database:
  host: prod-db.example.com
  password: "prod_secret_123"  # 如何安全管理？

# ❌ 問題：每個環境需要不同的 Docker image
# Dockerfile.production
COPY config.production.yaml /app/config.yaml
```

### Q3: .env 和 config.yaml 重複怎麼辦？

**答：** 使用環境變數覆蓋機制：

```yaml
# config.yaml
database:
  host: ${DB_HOST:-localhost}      # 優先用環境變數，否則用 localhost
  port: ${DB_PORT:-3306}
  charset: utf8mb4                  # 固定值，不用環境變數
```

## 總結

### 使用環境變數的情況

- ✅ 敏感資訊（密碼、金鑰、Token）
- ✅ 環境特定值（主機名、Port、資料庫名）
- ✅ 運行模式（debug/release、dev/prod）

### 使用配置檔案的情況

- ✅ 業務邏輯設定（重試次數、超時時間）
- ✅ 功能開關（Feature flags）
- ✅ 格式設定（日誌格式、日期格式）
- ✅ 預設值定義

### 黃金法則

```
如果配置值：
├─ 包含敏感資訊 → 環境變數
├─ 每個環境不同 → 環境變數
├─ 程式邏輯相關 → 配置檔案
└─ 不常變動的值 → 配置檔案
```

這樣的分離方式讓我們可以：
1. 安全地管理敏感資訊
2. 靈活地部署到不同環境
3. 清楚地組織配置結構
4. 遵循業界最佳實踐
