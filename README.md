# Go GraphQL Lab

基於 Go + Gin 框架的 GraphQL vs RESTful API 比較專案。

## 專案目標

實作並比較 GraphQL 與 RESTful API 的差異，包含前端互動介面展示。

## 快速開始

### 使用 Vagrant + Docker Engine (推薦生產環境學習)

```bash
# 1. 啟動 Vagrant VM
vagrant up

# 2. 進入 VM
vagrant ssh

# 3. 啟動開發環境
cd /vagrant
docker compose up -d

# 4. 健康檢查
curl http://localhost:8080/health
```

**詳細 Vagrant 安裝與操作**: [docs/vagrant/INSTALLATION.md](docs/vagrant/INSTALLATION.md)

### 直接使用 Docker (本機已安裝 Docker)

```bash
# 啟動開發環境
docker compose up -d

# 健康檢查
curl http://localhost:8080/health
```

## 多環境支援

專案展示如何透過 `APP_ENV` 切換環境配置，DEV 和 SIT 共用同一個資料庫：

| 環境 | API Port | APP_ENV | 配置檔案 | 資料庫 |
|------|----------|---------|----------|--------|
| DEV  | 8080     | development | config.yaml | graphqllab (共用) |
| SIT  | 8081     | sit | config.sit.yaml | graphqllab (共用) |

```bash
# 啟動 DEV 環境
docker compose up -d

# 啟動 SIT 環境（共用同一個 MySQL）
docker compose -f docker-compose.yml -f docker-compose.sit.yml up -d
```

**核心概念：**
- 兩個環境共用同一個 MySQL 容器（port 3306）
- SIT 只覆蓋部分配置（logging.level, server.mode）
- 其他配置（database, graphql）從 config.yaml 繼承
- 展示配置繼承機制

## 專案結構

```text
cmd/              # 應用程式入口點
  server/         # 主服務
internal/         # 私有程式碼（只有本專案可用）
  config/         # 配置管理
  handler/        # HTTP handlers
  service/        # 業務邏輯
  repository/     # 資料存取層
pkg/              # 公開庫（可被外部使用）
infra/            # 基礎設施
  dbinit/         # 資料庫初始化腳本
web/              # 前端檔案
  html/           # HTML 頁面
  static/         # JS/CSS 檔案
docs/             # 文件目錄
  vagrant/        # Vagrant 相關文件
  docker/         # Docker 相關文件
vagrant/          # Vagrant 配置
  provision.sh    # VM 自動化安裝腳本
Vagrantfile       # Vagrant VM 配置檔
```

## 核心技術決策

### 1. Go 專案結構

遵循 Go 標準專案佈局：

- `cmd/` - 可執行程式入口，保持簡潔
- `internal/` - 私有程式碼，Go 編譯器保證只有本專案能 import
- `pkg/` - 公開庫（若無需分享給外部則可省略）

### 2. 配置管理架構

核心原則：配置繼承 + 環境變數覆蓋

```yaml
# docker-compose.sit.yml
api:
  environment:
    APP_ENV: sit  # 只需要這一行
```

配置載入流程：

```text
1. 載入 config.yaml (基礎配置)
   ↓
2. 載入 config.sit.yaml (只覆蓋部分欄位)
   ↓
3. 環境變數覆蓋（選用）
```

配置繼承範例：

```yaml
# config.yaml (基礎配置)
database:
  host: mysql
  name: graphqllab
logging:
  level: debug

# config.sit.yaml (只覆蓋部分)
environment: sit
logging:
  level: info      # 覆蓋
server:
  mode: release    # 覆蓋
# database 不定義，從 config.yaml 繼承
```

為什麼選擇純 YAML 而非 Viper？

- 專案需求簡單，不需要複雜的配置管理
- 類型安全（編譯時檢查）
- 依賴輕量（只需 yaml.v3）
- 符合 KISS 原則

### 3. Go 依賴版本管理

專案使用三種 import 路徑，各有原因：

```go
// 現代標準 - 直接用 GitHub + Go Modules
github.com/go-sql-driver/mysql

// 歷史遺留但仍有效 - 版本化導入
gopkg.in/yaml.v3

// 自訂域名 - 專業化選擇
filippo.io/edwards25519
```

為什麼 `gopkg.in/yaml.v3`？

- 主版本號明確鎖定（v3.x.x）
- 避免意外的破壞性變更
- go-yaml 官方推薦的導入方式

## 配置優先順序

```text
環境變數 > 環境專屬 YAML > 基礎 YAML > 程式碼預設值
```

範例：

```yaml
# config.yaml (基礎)
database:
  host: mysql
  name: graphqllab
logging:
  level: debug

# config.sit.yaml (SIT 覆蓋)
logging:
  level: info  # 覆蓋基礎配置
# database 從 config.yaml 繼承
```

```bash
# 環境變數再次覆蓋
APP_ENV=sit LOG_LEVEL=warn go run cmd/server/main.go
```

最終結果：

```go
config.Database.Host = "mysql"       // 來自 config.yaml (繼承)
config.Database.Name = "graphqllab"  // 來自 config.yaml (繼承)
config.Logging.Level = "warn"        // 環境變數覆蓋
```

## 資料庫設計

使用 MySQL 8.0，包含三個主要資料表：

- `users` - 使用者資料
- `salaries` - 薪資明細
- `employment_status` - 到職狀態

初始化腳本位於 `infra/dbinit/`：

- `schema.sql` - 資料表結構
- `seed.sql` - 測試資料

## 開發進度

詳細任務規劃請參考：[AgentTask.md](AgentTask.md)

- ✅ Task 0001: Go 專案初始化
- ✅ Task 0002: MySQL 資料庫設計
- ✅ Task 0003: Docker Compose 多環境配置
- ✅ Task 0003-4: 整理重要知識到 README
- ✅ Task 0003-5: 簡化環境配置（配置繼承機制）
- ⏳ Task 0004: Repository Pattern 實作
- ⏳ Task 0005: Service Layer 實作
- ⏳ Task 0006: RESTful API 實作
- ⏳ Task 0007-0010: GraphQL 實作
- ⏳ Task 0011-0013: 前端介面開發
- ⏳ Task 0014-0015: 整合測試與效能比較

## 技術棧

### 後端

- Go 1.25+
- Gin（Web 框架）
- gqlgen（GraphQL）
- MySQL 8.0

### 前端

- HTML5 + CSS3
- Vanilla JavaScript (ES6+)

### DevOps

- Docker Engine (生產環境等級)
- Docker Compose (多環境配置)
- Vagrant + Hyper-V (開發 VM 管理)

## 開發環境設定

本專案提供兩種開發環境方式：

### 方案 1: Vagrant + Hyper-V + Docker Engine (推薦)

**優勢**: 100% 模擬生產環境，學習真實 Linux 部署技能。

**文件**:

- [Vagrant 安裝指南](docs/vagrant/INSTALLATION.md) - 從零開始安裝 Vagrant + Hyper-V
- [Vagrantfile 配置說明](docs/vagrant/CONFIGURATION.md) - 理解 VM 配置
- [Provision 自動化](docs/vagrant/PROVISIONING.md) - Docker 自動安裝流程
- [日常操作指南](docs/vagrant/OPERATIONS.md) - VM 生命週期管理
- [故障排除](docs/vagrant/TROUBLESHOOTING.md) - 常見問題解決

### 方案 2: Docker Desktop / 本機 Docker (快速開發)

適合已有 Docker 環境或快速驗證功能。

**文件**:

- [Docker Engine 操作教學](docs/docker/ENGINE_BASICS.md) - 完整 Docker 指令參考

## 文檔

- [AgentTask.md](AgentTask.md) - 詳細任務規劃
- [CONFIG_ARCHITECTURE_V2.md](CONFIG_ARCHITECTURE_V2.md) - 配置架構說明
- [QUICK_START_ENVIRONMENTS.md](QUICK_START_ENVIRONMENTS.md) - 多環境快速啟動
- [AGENTS.md](AGENTS.md) - 開發規則與指南

## 開發原則

1. **Keep It Simple** - 不過度工程化
2. **標準化** - 遵循 Go 最佳實踐
3. **教學優先** - 程式碼清晰易懂
4. **實用導向** - 專注於實際比較 GraphQL vs RESTful

## License

MIT
