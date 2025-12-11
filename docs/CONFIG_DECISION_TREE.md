# 配置決策樹：該放 Config 還是 Env？

快速決策指南，幫助你判斷配置應該放在哪裡。

## 決策流程圖

```
開始：我有一個配置值需要設定
    │
    ├─> 問題1：這是敏感資訊嗎？
    │   （密碼、金鑰、Token、API Key）
    │   │
    │   ├─ 是 ──> ✅ 使用環境變數 (.env)
    │   │         停止，不要繼續
    │   │
    │   └─ 否 ──> 繼續問題2
    │
    ├─> 問題2：這個值會因環境而不同嗎？
    │   （dev/sit/uat/prod 會使用不同的值）
    │   │
    │   ├─ 是 ──> ✅ 使用環境變數 (.env)
    │   │         （也可以考慮 config + env 混合）
    │   │
    │   └─ 否 ──> 繼續問題3
    │
    ├─> 問題3：這是業務邏輯相關的設定嗎？
    │   （如：重試次數、超時時間、功能開關）
    │   │
    │   ├─ 是 ──> ✅ 使用配置檔案 (config.yaml)
    │   │
    │   └─ 否 ──> 繼續問題4
    │
    └─> 問題4：這個值會經常變動嗎？
        │
        ├─ 是 ──> ✅ 使用環境變數 (.env)
        │
        └─ 否 ──> ✅ 使用配置檔案 (config.yaml)
```

## 快速對照表

| 配置類型 | 範例 | 位置 | 原因 |
|---------|------|------|------|
| 🔐 密碼 | `DB_PASSWORD` | .env | 敏感資訊 |
| 🔑 金鑰 | `JWT_SECRET`, `API_KEY` | .env | 敏感資訊 |
| 🌐 主機名 | `DB_HOST`, `REDIS_HOST` | .env | 環境差異 |
| 🚪 Port | `DB_PORT`, `API_PORT` | .env | 環境差異 |
| 📦 資料庫名 | `DB_NAME` | .env | 環境差異 |
| 🎚️ 運行模式 | `GIN_MODE`, `NODE_ENV` | .env | 環境差異 |
| 📊 日誌等級 | `LOG_LEVEL` | .env | 環境差異 |
| ⚙️ 連線池大小 | `max_connections` | config | 業務邏輯 |
| ⏱️ 超時設定 | `timeout`, `ttl` | config | 業務邏輯 |
| 🔄 重試次數 | `max_retries` | config | 業務邏輯 |
| 🎯 速率限制 | `rate_limit` | config | 業務規則 |
| 🎛️ 功能開關 | `enable_feature_x` | config | 業務邏輯 |
| 📝 日誌格式 | `log_format` | config | 程式邏輯 |
| 🔤 字元編碼 | `charset` | config | 固定設定 |

## 實例分析

### 案例 1：資料庫密碼

```
配置：database.password
問題1：是敏感資訊嗎？ → 是
結論：使用環境變數
```

```bash
# ✅ 正確
# .env
DB_PASSWORD=my_secret_password
```

```yaml
# ❌ 錯誤
# config.yaml
database:
  password: my_secret_password  # 不要這樣做！
```

### 案例 2：連線池大小

```
配置：database.max_connections
問題1：是敏感資訊嗎？ → 否
問題2：會因環境不同嗎？ → 否（通常所有環境都用 25）
問題3：是業務邏輯設定嗎？ → 是
結論：使用配置檔案
```

```yaml
# ✅ 正確
# config.yaml
database:
  max_connections: 25
```

### 案例 3：資料庫主機

```
配置：database.host
問題1：是敏感資訊嗎？ → 否
問題2：會因環境不同嗎？ → 是
  - dev: localhost
  - sit: mysql-sit.internal
  - uat: mysql-uat.internal
  - prod: mysql-prod.internal
結論：使用環境變數
```

```bash
# ✅ 正確
# .env.sit
DB_HOST=mysql-sit.internal

# .env.uat
DB_HOST=mysql-uat.internal
```

### 案例 4：GraphQL 查詢深度限制

```
配置：graphql.max_depth
問題1：是敏感資訊嗎？ → 否
問題2：會因環境不同嗎？ → 否（所有環境都限制 10 層）
問題3：是業務邏輯設定嗎？ → 是
結論：使用配置檔案
```

```yaml
# ✅ 正確
# config.yaml
graphql:
  query_complexity:
    max_depth: 10
```

### 案例 5：日誌等級

```
配置：logging.level
問題1：是敏感資訊嗎？ → 否
問題2：會因環境不同嗎？ → 是
  - dev: debug
  - sit: debug
  - uat: info
  - prod: warning
結論：使用環境變數
```

```bash
# ✅ 正確
# .env.dev
LOG_LEVEL=debug

# .env.prod
LOG_LEVEL=warning
```

## 混合使用：最佳實踐

有時候需要混合使用兩種方式：

### 策略 1：預設值在 Config，覆蓋用 Env

```yaml
# config.yaml - 提供預設值
database:
  host: localhost              # 預設值
  port: 3306                   # 預設值
  max_connections: 25          # 固定設定
```

```go
// Go 程式碼 - 環境變數可以覆蓋
cfg.Host = getEnv("DB_HOST", cfg.Host)        // 優先用環境變數
cfg.Port = getEnvInt("DB_PORT", cfg.Port)     // 優先用環境變數
// max_connections 不從環境變數讀取
```

### 策略 2：環境特定值用 Env，通用設定用 Config

```yaml
# config.yaml - 通用設定
database:
  charset: utf8mb4
  max_connections: 25
  timeout: 30s
  # host, port, password 等由環境變數提供
```

```bash
# .env - 環境特定
DB_HOST=localhost
DB_PORT=3306
DB_PASSWORD=secret
```

## 特殊情況處理

### 情況 1：開發測試需要不同值

**問題：** 開發時想用 `debug`，測試時想用 `info`，但不想每次都改 config.yaml

**解決：**
```yaml
# config.yaml
logging:
  level: debug                 # 開發預設值

# 執行時可以用環境變數覆蓋
# LOG_LEVEL=info go test ./...
```

### 情況 2：多個環境同時運行

**問題：** 想在同一台機器跑 dev、sit、uat

**解決：**
```bash
# 用不同的 port 和 .env 檔案
docker compose --env-file .env up       # dev: port 8080
docker compose --env-file .env.sit up   # sit: port 8081
docker compose --env-file .env.uat up   # uat: port 8082
```

### 情況 3：CI/CD 自動部署

**問題：** CI/CD 環境沒有 .env 檔案

**解決：**
```yaml
# CI/CD 配置（如 GitHub Actions）
env:
  DB_HOST: ${{ secrets.DB_HOST }}
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
  GIN_MODE: release

# 或使用 Kubernetes ConfigMap + Secret
```

## 檢查清單

在決定配置位置前，問自己：

- [ ] 這個值包含敏感資訊嗎？
  - 是 → 環境變數
- [ ] 不同環境會使用不同的值嗎？
  - 是 → 環境變數
- [ ] 這個值需要頻繁修改嗎？
  - 是 → 環境變數
- [ ] 這是業務邏輯或程式邏輯相關的設定嗎？
  - 是 → 配置檔案
- [ ] 所有環境都使用相同的值嗎？
  - 是 → 配置檔案
- [ ] 這個值可以公開嗎？
  - 是 → 配置檔案
  - 否 → 環境變數

## 最後建議

### ✅ DO（推薦做法）

1. 敏感資訊永遠用環境變數
2. 環境特定值用環境變數
3. 業務邏輯設定用配置檔案
4. 提供清楚的預設值
5. 環境變數加上前綴（如 `DB_`, `REDIS_`）
6. 寫清楚的註解說明

### ❌ DON'T（避免做法）

1. 不要把密碼寫在配置檔案中
2. 不要把所有東西都用環境變數
3. 不要把環境變數和配置混在一起沒有章法
4. 不要忘記寫文件說明哪些是必需的
5. 不要把 .env.prod 提交到 Git
6. 不要在多個地方重複定義相同的值

## 總結

```
敏感資訊 → 環境變數
環境差異 → 環境變數
業務邏輯 → 配置檔案
固定設定 → 配置檔案
```

當不確定時，優先考慮環境變數，因為：
- 更安全（不會提交到版本控制）
- 更靈活（容易在不同環境切換）
- 符合 12-Factor App 原則
- 容器化友善
