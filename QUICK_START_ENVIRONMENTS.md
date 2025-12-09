# 快速啟動指南 - 多環境配置

## 一鍵啟動各環境

### Windows

```cmd
# 開發環境 (DEV)
scripts\start-dev.bat

# 系統整合測試 (SIT)
scripts\start-sit.bat

# 使用者驗收測試 (UAT)
scripts\start-uat.bat
```

### Linux / macOS

```bash
# 開發環境 (DEV)
./scripts/start-dev.sh

# 系統整合測試 (SIT)
./scripts/start-sit.sh

# 使用者驗收測試 (UAT)
./scripts/start-uat.sh
```

## 環境對照表

| 環境 | MySQL Port | API Port | 資料庫名稱 | GIN Mode | 用途 |
|------|-----------|----------|-----------|----------|------|
| **DEV** | 3306 | 8080 | graphqllab | debug | 本地開發 |
| **SIT** | 3307 | 8081 | graphqllab_sit | debug | 整合測試 |
| **UAT** | 3308 | 8082 | graphqllab_uat | release | 驗收測試 |

## 測試連線

```bash
# DEV
curl http://localhost:8080/health

# SIT
curl http://localhost:8081/health

# UAT
curl http://localhost:8082/health
```

## 查看日誌

```bash
# DEV
docker compose logs -f

# SIT
docker compose -f docker-compose.yml -f docker-compose.sit.yml logs -f

# UAT
docker compose -f docker-compose.yml -f docker-compose.uat.yml logs -f
```

## 停止服務

```bash
# DEV
docker compose down

# SIT
docker compose -f docker-compose.yml -f docker-compose.sit.yml down

# UAT
docker compose -f docker-compose.yml -f docker-compose.uat.yml down
```

## 同時運行多環境

可以同時啟動 DEV、SIT、UAT 環境，互不干擾！

```bash
# 啟動所有環境
./scripts/start-dev.sh
./scripts/start-sit.sh
./scripts/start-uat.sh

# 驗證所有環境
curl http://localhost:8080/health  # DEV
curl http://localhost:8081/health  # SIT
curl http://localhost:8082/health  # UAT
```

## 配置檔案說明

- `.env` - 開發環境配置
- `.env.sit` - SIT 環境配置
- `.env.uat` - UAT 環境配置
- `.env.prod` - 正式環境配置（不提交到 Git）

## 詳細文件

完整說明請參考 [ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md)
