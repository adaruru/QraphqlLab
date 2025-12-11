# GraphQL Lab 配置架構圖

本文件提供視覺化的系統架構說明。

## 配置管理架構

```
┌─────────────────────────────────────────────────────────────────┐
│                     GraphQL Lab 配置系統                         │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────┐    ┌──────────────────────┐
│   配置檔案層         │    │   環境變數層         │
│  (config.yaml)       │    │     (.env)           │
├──────────────────────┤    ├──────────────────────┤
│ • 業務邏輯設定       │    │ • 敏感資訊           │
│ • 功能開關           │    │ • 環境特定值         │
│ • 固定參數           │    │ • 運行模式           │
│ • 預設值             │    │ • 動態配置           │
└──────────┬───────────┘    └───────────┬──────────┘
           │                            │
           │    ┌──────────────────────┴───────┐
           │    │   配置優先順序               │
           │    │   1. 環境變數（最高）        │
           └────┤   2. .env 檔案               │
                │   3. config.yaml             │
                │   4. 程式碼預設值（最低）    │
                └──────────────────────────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │   應用程式            │
                │  (cmd/server/main.go) │
                └──────────────────────┘
```

## 多環境架構

```
┌─────────────────────────────────────────────────────────────────┐
│                        同一台主機                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────────┐
│  │   DEV 環境         │  │   SIT 環境         │  │   UAT 環境         │
│  ├────────────────────┤  ├────────────────────┤  ├────────────────────┤
│  │ Container:         │  │ Container:         │  │ Container:         │
│  │ graphqllab-api     │  │ graphqllab-api-sit │  │ graphqllab-api-uat │
│  │                    │  │                    │  │                    │
│  │ Ports:             │  │ Ports:             │  │ Ports:             │
│  │ • MySQL: 3306      │  │ • MySQL: 3307      │  │ • MySQL: 3308      │
│  │ • API: 8080        │  │ • API: 8081        │  │ • API: 8082        │
│  │                    │  │                    │  │                    │
│  │ Database:          │  │ Database:          │  │ Database:          │
│  │ graphqllab         │  │ graphqllab_sit     │  │ graphqllab_uat     │
│  │                    │  │                    │  │                    │
│  │ Volume:            │  │ Volume:            │  │ Volume:            │
│  │ mysql_data         │  │ mysql_data_sit     │  │ mysql_data_uat     │
│  │                    │  │                    │  │                    │
│  │ Config:            │  │ Config:            │  │ Config:            │
│  │ .env               │  │ .env.sit           │  │ .env.uat           │
│  │ docker-compose.yml │  │ + docker-compose   │  │ + docker-compose   │
│  │                    │  │   .sit.yml         │  │   .uat.yml         │
│  └────────────────────┘  └────────────────────┘  └────────────────────┘
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
           ▲                    ▲                    ▲
           │                    │                    │
    start-dev.sh          start-sit.sh          start-uat.sh
```

## Docker Compose 合併流程

```
啟動命令：
docker compose -f docker-compose.yml -f docker-compose.sit.yml --env-file .env.sit up

                        ▼

    ┌─────────────────────────────────────────────┐
    │  Step 1: 載入基礎配置                       │
    │  docker-compose.yml                         │
    ├─────────────────────────────────────────────┤
    │  services:                                  │
    │    mysql:                                   │
    │      image: mysql:8.0                       │
    │      ports: ["3306:3306"]                   │
    │      environment:                           │
    │        MYSQL_DATABASE: ${MYSQL_DATABASE}    │
    │    api:                                     │
    │      build: .                               │
    │      ports: ["8080:8080"]                   │
    └─────────────────┬───────────────────────────┘
                      │
                      ▼
    ┌─────────────────────────────────────────────┐
    │  Step 2: 載入環境變數                       │
    │  .env.sit                                   │
    ├─────────────────────────────────────────────┤
    │  MYSQL_DATABASE=graphqllab_sit              │
    │  MYSQL_USER=graphqluser_sit                 │
    │  MYSQL_PASSWORD=sit_password                │
    │  API_PORT=8081                              │
    └─────────────────┬───────────────────────────┘
                      │
                      ▼
    ┌─────────────────────────────────────────────┐
    │  Step 3: 套用環境覆蓋配置                   │
    │  docker-compose.sit.yml                     │
    ├─────────────────────────────────────────────┤
    │  services:                                  │
    │    mysql:                                   │
    │      container_name: graphqllab-mysql-sit   │
    │      ports: ["3307:3306"]  # 覆蓋！         │
    │    api:                                     │
    │      container_name: graphqllab-api-sit     │
    │      ports: ["8081:8080"]  # 覆蓋！         │
    └─────────────────┬───────────────────────────┘
                      │
                      ▼
    ┌─────────────────────────────────────────────┐
    │  Step 4: 最終合併結果                       │
    ├─────────────────────────────────────────────┤
    │  services:                                  │
    │    mysql:                                   │
    │      image: mysql:8.0                       │
    │      container_name: graphqllab-mysql-sit   │
    │      ports: ["3307:3306"]                   │
    │      environment:                           │
    │        MYSQL_DATABASE: graphqllab_sit       │
    │        MYSQL_USER: graphqluser_sit          │
    │        MYSQL_PASSWORD: sit_password         │
    │    api:                                     │
    │      build: .                               │
    │      container_name: graphqllab-api-sit     │
    │      ports: ["8081:8080"]                   │
    └─────────────────────────────────────────────┘
```

## 配置讀取流程

```
應用程式啟動
    │
    ├──> 初始化配置物件
    │    config := &Config{
    │      Database: DatabaseConfig{
    │        Charset: "utf8mb4",      // 程式碼預設值
    │        MaxConnections: 25,
    │      },
    │    }
    │
    ├──> 讀取 config.yaml（如果存在）
    │    │
    │    ├─ database.charset = "utf8mb4"  ✓ 保持
    │    ├─ database.max_connections = 50 ✓ 更新為 50
    │    └─ database.timeout = 30s        ✓ 新增
    │
    ├──> 讀取環境變數（優先權最高）
    │    │
    │    ├─ DB_HOST = "mysql-sit"         ✓ 設定
    │    ├─ DB_PORT = "3306"              ✓ 設定
    │    ├─ DB_USER = "graphqluser_sit"   ✓ 設定
    │    ├─ DB_PASSWORD = "secret"        ✓ 設定（敏感）
    │    └─ DB_NAME = "graphqllab_sit"    ✓ 設定
    │
    └──> 最終配置
         {
           Database: {
             Host: "mysql-sit",          // 來自環境變數
             Port: 3306,                 // 來自環境變數
             User: "graphqluser_sit",    // 來自環境變數
             Password: "secret",         // 來自環境變數
             Name: "graphqllab_sit",     // 來自環境變數
             Charset: "utf8mb4",         // 來自 config.yaml
             MaxConnections: 50,         // 來自 config.yaml
             Timeout: 30s,               // 來自 config.yaml
           }
         }
```

## 配置決策流程

```
有一個配置值需要設定
    │
    ▼
┌─────────────────────────┐
│ 是敏感資訊嗎？          │
│ (密碼、金鑰、Token)      │
└────┬───────────────┬────┘
     │ 是            │ 否
     ▼               ▼
┌────────────┐  ┌─────────────────────────┐
│ 環境變數   │  │ 會因環境不同嗎？        │
│ (.env)     │  │ (dev/sit/uat/prod)      │
└────────────┘  └────┬───────────────┬────┘
                     │ 是            │ 否
                     ▼               ▼
                ┌────────────┐  ┌─────────────────────────┐
                │ 環境變數   │  │ 是業務邏輯設定嗎？      │
                │ (.env)     │  │ (重試、超時、功能開關)  │
                └────────────┘  └────┬───────────────┬────┘
                                     │ 是            │ 否
                                     ▼               ▼
                                ┌────────────┐  ┌────────────┐
                                │ 配置檔案   │  │ 環境變數   │
                                │ (config)   │  │ (.env)     │
                                └────────────┘  └────────────┘
```

## 資料流向圖

```
                    ┌─────────────┐
                    │ 使用者請求  │
                    └──────┬──────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │         Gin Router               │
        │      (HTTP Request Handler)      │
        └──────────┬───────────────────────┘
                   │
                   ▼
        ┌──────────────────────────────────┐
        │         Handler Layer            │
        │    (REST / GraphQL Handlers)     │
        └──────────┬───────────────────────┘
                   │
                   ▼
        ┌──────────────────────────────────┐
        │         Service Layer            │
        │      (Business Logic)            │
        └──────────┬───────────────────────┘
                   │
                   ▼
        ┌──────────────────────────────────┐
        │       Repository Layer           │
        │      (Data Access)               │
        └──────────┬───────────────────────┘
                   │
                   ▼
        ┌──────────────────────────────────┐
        │          Database                │
        │   (MySQL with Config from Env)   │
        └──────────────────────────────────┘
                   ▲
                   │
         ┌─────────┴─────────┐
         │                   │
    ┌────────────┐    ┌─────────────┐
    │ DB_HOST    │    │ DB_PASSWORD │
    │ (來自 .env)│    │ (來自 .env) │
    └────────────┘    └─────────────┘
```

## 檔案組織結構

```
QraphqlLab/
│
├── cmd/                          # 應用程式入口
│   └── server/
│       └── main.go              # 讀取配置並啟動
│
├── internal/
│   └── config/
│       └── database.go          # 配置結構定義
│
├── infra/
│   ├── Dockerfile.mysql         # MySQL 容器定義
│   └── dbinit/
│       ├── schema.sql           # 資料庫架構
│       └── seed.sql             # 測試資料
│
├── scripts/
│   ├── start-dev.sh             # DEV 啟動腳本
│   ├── start-sit.sh             # SIT 啟動腳本
│   └── start-uat.sh             # UAT 啟動腳本
│
├── docs/
│   ├── CONFIG_VS_ENV.md         # 配置哲學說明
│   ├── CONFIG_DECISION_TREE.md  # 決策樹
│   └── ARCHITECTURE.md          # 本文件
│
├── .env                         # DEV 環境變數（不提交）
├── .env.sit                     # SIT 環境變數（不提交）
├── .env.uat                     # UAT 環境變數（不提交）
├── .env.prod                    # PROD 環境變數（不提交）
│
├── config.example.yaml          # 配置範例（提交）
├── config.detailed.example.yaml # 詳細範例（提交）
│
├── docker-compose.yml           # 基礎配置（提交）
├── docker-compose.sit.yml       # SIT 覆蓋（提交）
├── docker-compose.uat.yml       # UAT 覆蓋（提交）
└── docker-compose.prod.yml      # PROD 覆蓋（提交）
```

## 安全層級圖

```
┌─────────────────────────────────────────────────────────┐
│                      安全等級                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 🔴 最高安全等級 - 絕不提交到 Git              │      │
│  ├──────────────────────────────────────────────┤      │
│  │ • .env.prod                                   │      │
│  │ • .env.uat                                    │      │
│  │ • .env                                        │      │
│  │   包含：DB_PASSWORD, JWT_SECRET, API_KEY      │      │
│  └──────────────────────────────────────────────┘      │
│                     ▲                                   │
│                     │ .gitignore                        │
│  ┌──────────────────────────────────────────────┐      │
│  │ 🟡 中等安全等級 - 可以提交參考版本            │      │
│  ├──────────────────────────────────────────────┤      │
│  │ • .env.sit (團隊內部使用)                     │      │
│  │ • config.example.yaml                         │      │
│  │   包含：預設值、結構說明                      │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │ 🟢 公開級別 - 安全提交                        │      │
│  ├──────────────────────────────────────────────┤      │
│  │ • config.yaml                                 │      │
│  │ • docker-compose.yml                          │      │
│  │ • docker-compose.*.yml                        │      │
│  │   包含：業務邏輯設定、固定參數                │      │
│  └──────────────────────────────────────────────┘      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 環境變數傳遞路徑

```
┌──────────────┐
│   .env.sit   │  MYSQL_PASSWORD=secret
└──────┬───────┘
       │
       │ docker compose --env-file .env.sit
       │
       ▼
┌────────────────────┐
│ Docker Compose     │  讀取並解析環境變數
└──────┬─────────────┘
       │
       │ 設定 container environment
       │
       ▼
┌────────────────────┐
│ Docker Container   │  MYSQL_PASSWORD=secret (環境變數)
│ (graphqllab-api)   │
└──────┬─────────────┘
       │
       │ os.Getenv("MYSQL_PASSWORD")
       │
       ▼
┌────────────────────┐
│ Go Application     │  password := "secret"
│ (main.go)          │
└──────┬─────────────┘
       │
       │ 建立資料庫連線
       │
       ▼
┌────────────────────┐
│ MySQL Database     │  驗證密碼並連線
└────────────────────┘
```

## 總結

這個架構提供：

1. ✅ **安全性** - 敏感資訊不外洩
2. ✅ **靈活性** - 輕鬆切換環境
3. ✅ **隔離性** - 環境互不干擾
4. ✅ **可維護性** - 清楚的結構
5. ✅ **可擴展性** - 易於新增環境

所有配置遵循：
- 12-Factor App 原則
- Docker 最佳實踐
- 安全性優先
- 開發體驗友好
