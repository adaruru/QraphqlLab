# Go GraphQL POC 專案任務規劃

## 專案目標
建立一個基於 Go Gin 框架的 API 專案，實作 GraphQL 與 RESTful API 的比較示範，包含前端互動介面。

---

## 任務執行順序

### 階段一：基礎環境建置

#### 0001 初始化 Go 專案
**目標：** 建立基礎 Go 專案結構
- [x] 初始化 `go mod`
- [x] 建立專案目錄結構
  ```
  /cmd          # 主程式入口
  /internal     # 內部套件
    /handler    # API handlers
    /model      # 資料模型
    /service    # 業務邏輯
    /repository # 資料存取層
  /web          # 前端靜態檔案
    /html       # HTML 頁面
    /static     # JS/CSS 檔案
  /docker       # Docker 相關檔案
  ```
- [x] 建立 `.gitignore`
- [x] 安裝 Gin 框架：`go get -u github.com/gin-gonic/gin`

#### 0002 MySQL 資料庫設計與實作
**目標：** 設計資料庫架構並建立測試資料
- [x] 設計資料表結構（例如：users, products, orders）
- [x] 建立 SQL schema 檔案 `infra/dbinit/schema.sql`
  - [x] 使用者資料、薪資明細、到職狀態，供後續前端實作 graphql join 效果
- [x] 建立測試資料 SQL 檔案 `infra/dbinit/seed.sql`
  - [x] 新增測試資料，使用者資料、薪資明細、到職狀態，供後續前端實作 graphql join 效果
- [x] 安裝 MySQL driver：`go get -u github.com/go-sql-driver/mysql`
- [x] 建立資料庫連線設定檔

#### 0003 Docker Compose 環境配置
**目標：** 建立容器化開發環境
- [x] MySQL `Dockerfile`
  - MySQL 服務 image
  - Dockerfile copy `infra/dbinit/*`
  - schema.sql
  - seed.sql
- [x] 建立 `Dockerfile` for Go application
- [x] 建立 `docker-compose.yml`
  - MySQL 服務（port 3306）
  - Go API 服務（port 8080）
- [x] 設定環境變數檔案 `.env`
- [x] 測試 Docker Compose 啟動與連線

#### 0003-1 檢查 infra\Dockerfile.mysql
- ENV MYSQL_DATABASE=graphqllab 這可以直接設定
- ENV MYSQL_ROOT_PASSWORD=rootpassword
- 但登入者、PASSWORD 理應規劃在 docker compose
同時運行多個環境

### 可以同時運行！
./scripts/start-dev.sh  # Port: 3306, 8080
./scripts/start-sit.sh  # Port: 3307, 8081
./scripts/start-uat.sh  # Port: 3308, 8082
📊 環境變數完整流程圖
啟動腳本 (start-sit.sh)
    │
    ├─> 檢查 .env.sit 存在
    │
    ├─> 載入 .env.sit 環境變數
    │       MYSQL_DATABASE=graphqllab_sit
    │       API_PORT=8081
    │       ...
    │
    ├─> 執行 docker compose
    │       -f docker-compose.yml        (基礎配置)
    │       -f docker-compose.sit.yml    (SIT 覆蓋)
    │       --env-file .env.sit          (環境變數檔案)
    │
    ├─> Docker Compose 合併配置
    │       基礎配置 + SIT 覆蓋 + .env.sit
    │
    ├─> 建立 Container
    │       Name: graphqllab-mysql-sit
    │       Port: 3307:3306
    │       Env: MYSQL_DATABASE=graphqllab_sit
    │
    └─> 應用程式讀取環境變數
            os.Getenv("DB_NAME") -> "graphqllab_sit"

#### 0003-2 說明 config.example.yaml
- 新增 congif.uat、config.sit 與對應執行 compose 腳本，要可以辨識出環境變數寫入得方法

#### 0003-3 說明 config.example.yaml
-  環境變數為什麼要分 有的地方 config 有的放 env
-  使用結論: 只放 config、移除所有env
-  只用 yaml 不使用 viper
-  版本引用差異: 現代專案，直接用 GitHub、歷史原因 gopkg 仍適用、作者選擇用自己的域名，顯示專業性
---

#### 0003-4 閱讀所有 task 0001-0003-3
- 只擷取結論更新於 README.md
- 重要知識紀錄於 README.md

#### 0003-5 不應該有 uat 環境

- 應該只有一個 sit 環境展示切環境效果
- 應該只有一個 compose 檔執行 sit 啟用 container
- 應該只有一個 db ，所有環境共用 ，sit config 不應該出現其他 db 連線，應該直接移除，不覆蓋而使用 config.yaml 來顯現兩個檔案都會讀的效果 

### 階段一之二：資料存取層實作

#### 0003-6 新增 Vagrant 開發環境

- [x] 建立 Vagrantfile 配置
  - [x] 使用 ubuntu/jammy64 box
  - [x] RAM 2G, Disk 100G
  - [x] 網路配置 (Private Network + Port Forwarding)
  - [x] Hyper-V Provider 設定
  - [x] 同步資料夾配置
- [x] 建立 provision.sh 自動化腳本
  - [x] 安裝 Docker Engine
  - [x] 建立使用者 (admin, 密碼: adaruru)
  - [x] 設定 root 密碼 (adaruru)
  - [x] 配置使用者權限 (docker group)
- [x] 建立完整文件
  - [x] INSTALLATION.md - Vagrant 安裝指南
  - [x] CONFIGURATION.md - Vagrantfile 配置詳解
  - [x] PROVISIONING.md - Provision 腳本說明
  - [x] OPERATIONS.md - 日常操作指南
  - [x] TROUBLESHOOTING.md - 常見問題排除
  - [x] ENGINE_BASICS.md - Docker Engine 操作教學
- [x] 更新 README.md 整合 Vagrant 說明

### 階段二：資料存取層實作

#### 0004 實作 Repository Pattern
**目標：** 建立資料存取層
- [ ] 建立 DB 連線管理 `db.go`
- [ ] 實作 Repository interface
- [ ] 實作 MySQL Repository
  - GetAll() - 取得所有資料
  - GetByID() - 依 ID 取得資料
  - Create() - 新增資料
  - Update() - 更新資料
  - Delete() - 刪除資料
- [ ] 單元測試 Repository 層

#### 0005 實作 Service Layer
**目標：** 建立業務邏輯層
- [ ] 建立 Service interface
- [ ] 實作業務邏輯處理
- [ ] 錯誤處理與驗證
- [ ] 單元測試 Service 層

---

### 階段三：RESTful API 實作

#### 0006 實作 RESTful API 端點
**目標：** 建立標準 REST API
- [ ] 設定 Gin Router
- [ ] 實作 CRUD endpoints
  - `GET /api/users` - 取得所有使用者
  - `GET /api/users/:id` - 取得單一使用者
  - `POST /api/users` - 新增使用者
  - `PUT /api/users/:id` - 更新使用者
  - `DELETE /api/users/:id` - 刪除使用者
- [ ] 實作 Response 標準格式
- [ ] 錯誤處理 middleware
- [ ] 測試所有 RESTful endpoints

---

### 階段四：GraphQL 實作

#### 0007 設定 GraphQL 框架
**目標：** 整合 GraphQL 到專案
- [ ] 安裝 gqlgen：`go get github.com/99designs/gqlgen`
- [ ] 初始化 gqlgen：`go run github.com/99designs/gqlgen init`
- [ ] 設定 `gqlgen.yml` 配置檔
- [ ] 建立 GraphQL schema 目錄結構

#### 0008 定義 GraphQL Schema
**目標：** 設計 GraphQL API 架構
- [ ] 定義 Type definitions (`schema.graphqls`)
  - User type
  - Query type (查詢操作)
  - Mutation type (變更操作)
  - Input types
- [ ] 設定 Resolver 結構
- [ ] 生成 GraphQL code：`go generate ./...`

#### 0009 實作 GraphQL Resolvers
**目標：** 實作 GraphQL 查詢與變更邏輯
- [ ] 實作 Query resolvers
  - users() - 取得所有使用者
  - user(id) - 取得單一使用者
- [ ] 實作 Mutation resolvers
  - createUser() - 新增使用者
  - updateUser() - 更新使用者
  - deleteUser() - 刪除使用者
- [ ] 整合 Service layer
- [ ] 錯誤處理
- [ ] 測試 GraphQL endpoints

#### 0010 設定 GraphQL Playground
**目標：** 啟用 GraphQL 開發工具
- [ ] 設定 GraphQL Playground route (`/graphql`)
- [ ] 測試 GraphQL 查詢介面
- [ ] 撰寫範例查詢文件

---

### 階段五：前端介面開發

#### 0011 建立 RESTful API 前端介面
**目標：** 實作 RESTful API 呼叫的 HTML 頁面
- [ ] 建立 `web/html/restful.html`
  - 顯示使用者列表
  - 新增使用者表單
  - 編輯/刪除按鈕
- [ ] 建立 `web/static/js/restful.js`
  - fetch API 呼叫
  - DOM 操作處理
  - 錯誤處理與提示
- [ ] 建立基礎 CSS 樣式
- [ ] 設定 Gin 靜態檔案服務
- [ ] 測試前端互動功能

#### 0012 建立 GraphQL 前端介面
**目標：** 實作 GraphQL API 呼叫的 HTML 頁面
- [ ] 建立 `web/html/graphql.html`
  - 顯示使用者列表
  - 新增使用者表單
  - 編輯/刪除按鈕
  - GraphQL Query 輸入框（可選）
- [ ] 建立 `web/static/js/graphql.js`
  - GraphQL Query 構建
  - fetch API 呼叫 GraphQL endpoint
  - Response 資料處理
  - 錯誤處理與提示
- [ ] 共用 CSS 樣式
- [ ] 測試前端互動功能

#### 0013 建立首頁與導航
**目標：** 建立專案展示入口
- [ ] 建立 `web/html/index.html`
  - 專案說明
  - RESTful vs GraphQL 比較說明
  - 導航連結到兩個示範頁面
- [ ] 美化 UI 介面
- [ ] 響應式設計調整

---

### 階段六：整合測試與效能比較

#### 0014 整合測試
**目標：** 完整測試所有功能
- [ ] 使用 Docker Compose 啟動完整環境
- [ ] 測試 RESTful API 所有 endpoints
- [ ] 測試 GraphQL API 所有 queries 和 mutations
- [ ] 測試前端兩個頁面的所有功能
- [ ] 跨瀏覽器測試
- [ ] 錯誤情境測試

#### 0015 效能比較與文檔
**目標：** 比較兩種 API 的差異
- [ ] 實作簡單的 benchmark 測試
- [ ] 記錄效能數據
  - Response size 比較
  - Response time 比較
  - 網路請求次數比較
- [ ] 更新 README.md
  - 專案介紹
  - 安裝與執行步驟
  - API 使用說明
  - RESTful vs GraphQL 比較結論
  - 架構圖與截圖
- [ ] 建立 API 文檔
- [ ] 建立 Postman collection（可選）

---

## 技術棧總覽

### 後端
- **語言：** Go 1.21+
- **框架：** Gin
- **GraphQL：** gqlgen
- **資料庫：** MySQL 8.0
- **ORM/Driver：** go-sql-driver/mysql

### 前端
- **HTML5** + **CSS3**
- **Vanilla JavaScript** (ES6+)
- **Fetch API** for HTTP requests

### DevOps
- **Docker** + **Docker Compose**
- **Git** version control

---

## 預期成果

1. ✅ 完整的 Go Gin API 專案
2. ✅ RESTful API endpoints
3. ✅ GraphQL API endpoints
4. ✅ 兩個互動式前端介面（RESTful vs GraphQL）
5. ✅ Docker Compose 一鍵啟動環境
6. ✅ 完整的專案文檔
7. ✅ 實際效能比較數據

---

## 開發注意事項

- 每個階段完成後進行測試再進入下一階段
- 保持程式碼簡潔，適當註解
- 遵循 Go 的最佳實踐和命名規範
- 前端保持簡單，重點在功能展示
- GraphQL 查詢設計要能展現其優勢（如：精確欄位選擇、減少請求次數）
