# Docker Engine 基礎操作指南

本文件說明在 Vagrant VM 內使用 Docker Engine 的完整操作流程，適用於生產環境。

---

## 前言：為什麼是 Docker Engine？

### Docker Engine vs Docker Desktop

| 項目 | Docker Engine | Docker Desktop |
|------|---------------|----------------|
| 使用環境 | Linux Server (生產環境) | Windows/Mac (開發環境) |
| 架構 | 原生 Docker Daemon | 虛擬化層 + GUI |
| 企業授權 | ✅ 完全免費 | ⚠️ 商業授權 |
| 學習價值 | ✅ 生產技能 | ❌ 抽象化工具 |
| 管理方式 | CLI (命令列) | GUI + CLI |

**本專案選擇**: Docker Engine，與生產環境 100% 一致。

---

## 基礎概念

### Docker 核心元件

```
Docker Engine
    ├── Docker Daemon (dockerd)      # 背景服務
    ├── Docker CLI (docker)          # 命令列工具
    └── containerd                   # 容器執行時
```

### 基本流程

```
Dockerfile
    ↓ (docker build)
Docker Image (映像檔)
    ↓ (docker run)
Docker Container (容器)
```

---

## Docker 生命週期管理

### 1. 啟動 Docker 服務

```bash
# 查看 Docker 服務狀態
sudo systemctl status docker

# 啟動 Docker
sudo systemctl start docker

# 停止 Docker
sudo systemctl stop docker

# 重新啟動 Docker
sudo systemctl restart docker

# 開機自動啟動
sudo systemctl enable docker
```

**驗證安裝**:
```bash
docker --version
# Docker version 24.0.x, build xxxxx

docker info
# 顯示 Docker 系統資訊
```

---

### 2. Hello World 測試

```bash
# 執行測試容器
docker run hello-world
```

**執行流程**:
```
[1] 本機查找 hello-world image
    ↓ (未找到)
[2] 從 Docker Hub 下載 image
    ↓
[3] 建立並執行 container
    ↓
[4] 顯示訊息後自動停止
```

---

## Image (映像檔) 管理

### 查看 Images

```bash
# 列出本機所有 images
docker images

# 或使用
docker image ls
```

輸出範例:
```
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
mysql         8.0       abc123def456   2 weeks ago    517MB
golang        1.21      def456abc789   3 weeks ago    810MB
hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
```

---

### 下載 Image

```bash
# 下載最新版本
docker pull mysql

# 下載指定版本
docker pull mysql:8.0

# 下載指定平台
docker pull --platform linux/amd64 mysql:8.0
```

---

### 刪除 Image

```bash
# 刪除單一 image
docker rmi mysql:8.0

# 強制刪除 (即使有容器使用)
docker rmi -f mysql:8.0

# 刪除多個 images
docker rmi mysql:8.0 golang:1.21

# 刪除所有未使用的 images
docker image prune -a
```

---

### 建置 Image

```bash
# 從 Dockerfile 建置
docker build -t my-app:1.0 .

# 指定 Dockerfile 路徑
docker build -t my-app:1.0 -f docker/Dockerfile .

# 建置時傳入參數
docker build --build-arg GO_VERSION=1.21 -t my-app:1.0 .

# 不使用快取
docker build --no-cache -t my-app:1.0 .
```

---

## Container (容器) 管理

### 執行容器

#### 基本執行

```bash
# 前景執行 (會佔用終端機)
docker run nginx

# 背景執行 (-d: detached)
docker run -d nginx

# 指定容器名稱
docker run -d --name my-nginx nginx

# 執行後自動刪除 (--rm)
docker run --rm nginx
```

#### Port Mapping

```bash
# 映射 Port (主機:容器)
docker run -d -p 8080:80 nginx

# 多個 Port
docker run -d -p 8080:80 -p 8443:443 nginx

# 隨機 Port
docker run -d -P nginx
```

#### 環境變數

```bash
# 單一變數
docker run -d -e MYSQL_ROOT_PASSWORD=secret mysql:8.0

# 多個變數
docker run -d \
  -e MYSQL_ROOT_PASSWORD=secret \
  -e MYSQL_DATABASE=mydb \
  mysql:8.0

# 從檔案載入
docker run -d --env-file .env mysql:8.0
```

#### Volume 掛載

```bash
# Named Volume
docker run -d -v mysql-data:/var/lib/mysql mysql:8.0

# Bind Mount (掛載 Host 目錄)
docker run -d -v /path/on/host:/path/in/container nginx

# 唯讀掛載
docker run -d -v /path/on/host:/path/in/container:ro nginx
```

---

### 查看容器

```bash
# 執行中的容器
docker ps

# 所有容器 (包含已停止)
docker ps -a

# 只顯示容器 ID
docker ps -q

# 格式化輸出
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
```

---

### 容器操作

#### 停止/啟動

```bash
# 停止容器 (SIGTERM，優雅關閉)
docker stop my-nginx

# 強制停止 (SIGKILL)
docker kill my-nginx

# 啟動已停止的容器
docker start my-nginx

# 重新啟動
docker restart my-nginx
```

#### 暫停/恢復

```bash
# 暫停容器 (凍結程序)
docker pause my-nginx

# 恢復容器
docker unpause my-nginx
```

#### 刪除容器

```bash
# 刪除已停止的容器
docker rm my-nginx

# 強制刪除執行中的容器
docker rm -f my-nginx

# 刪除所有已停止的容器
docker container prune
```

---

### 進入容器

```bash
# 執行互動式 Shell (容器必須在執行中)
docker exec -it my-nginx bash

# 執行單一指令
docker exec my-nginx ls /etc

# 以 root 身分執行
docker exec -u root -it my-nginx bash

# 若容器無 bash，使用 sh
docker exec -it my-nginx sh
```

---

### 查看容器資訊

#### 日誌

```bash
# 查看日誌
docker logs my-nginx

# 即時跟蹤日誌 (-f: follow)
docker logs -f my-nginx

# 顯示最後 100 行
docker logs --tail 100 my-nginx

# 顯示時間戳記
docker logs -t my-nginx
```

#### 資源使用

```bash
# 即時監控所有容器
docker stats

# 監控特定容器
docker stats my-nginx

# 只顯示一次 (不持續更新)
docker stats --no-stream
```

#### 詳細資訊

```bash
# 查看容器完整資訊 (JSON 格式)
docker inspect my-nginx

# 查詢特定欄位
docker inspect -f '{{.State.Status}}' my-nginx
docker inspect -f '{{.NetworkSettings.IPAddress}}' my-nginx
```

#### 程序資訊

```bash
# 查看容器內執行的程序
docker top my-nginx
```

---

## Docker Compose 操作

### 基本指令

```bash
# 啟動所有服務 (背景執行)
docker compose up -d

# 前景執行 (查看日誌)
docker compose up

# 只建置 Images，不啟動
docker compose build

# 建置並啟動
docker compose up -d --build

# 停止服務 (保留容器)
docker compose stop

# 停止並刪除容器
docker compose down

# 停止並刪除容器、網路、Volumes
docker compose down -v
```

---

### 查看服務

```bash
# 查看服務狀態
docker compose ps

# 查看日誌
docker compose logs

# 即時跟蹤日誌
docker compose logs -f

# 查看特定服務日誌
docker compose logs -f api
docker compose logs -f mysql

# 查看最後 50 行
docker compose logs --tail 50
```

---

### 服務操作

```bash
# 重新啟動服務
docker compose restart

# 重新啟動特定服務
docker compose restart api

# 執行一次性指令
docker compose run api go version

# 進入服務容器
docker compose exec api bash
docker compose exec mysql mysql -u root -p

# 擴展服務 (多個副本)
docker compose up -d --scale api=3
```

---

### 配置驗證

```bash
# 驗證 docker-compose.yml 語法
docker compose config

# 查看合併後的配置 (多檔案)
docker compose -f docker-compose.yml -f docker-compose.sit.yml config

# 列出服務
docker compose config --services
```

---

## 網路管理

### 查看網路

```bash
# 列出所有網路
docker network ls

# 查看網路詳細資訊
docker network inspect bridge
```

### 建立網路

```bash
# 建立自訂網路
docker network create my-network

# 指定 Subnet
docker network create --subnet=172.18.0.0/16 my-network
```

### 連線網路

```bash
# 容器連線到網路
docker network connect my-network my-nginx

# 容器斷開網路
docker network disconnect my-network my-nginx
```

### 刪除網路

```bash
# 刪除網路
docker network rm my-network

# 刪除所有未使用的網路
docker network prune
```

---

## Volume 管理

### 查看 Volumes

```bash
# 列出所有 volumes
docker volume ls

# 查看 volume 詳細資訊
docker volume inspect mysql-data
```

### 建立 Volume

```bash
# 建立 named volume
docker volume create mysql-data
```

### 刪除 Volume

```bash
# 刪除 volume
docker volume rm mysql-data

# 刪除所有未使用的 volumes (危險！)
docker volume prune
```

### 備份與還原

#### 備份 Volume

```bash
# 備份 mysql-data volume
docker run --rm \
  -v mysql-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/mysql-data-backup.tar.gz -C /data .
```

#### 還原 Volume

```bash
# 還原至 mysql-data volume
docker run --rm \
  -v mysql-data:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/mysql-data-backup.tar.gz -C /data
```

---

## 系統清理

### 清理未使用的資源

```bash
# 刪除停止的容器
docker container prune

# 刪除未使用的 images
docker image prune

# 刪除未使用的 volumes
docker volume prune

# 刪除未使用的 networks
docker network prune

# 一次清理所有 (危險！)
docker system prune

# 包含所有未使用的 images
docker system prune -a

# 包含 volumes
docker system prune -a --volumes
```

---

### 查看磁碟使用

```bash
# 查看 Docker 磁碟使用情況
docker system df

# 詳細輸出
docker system df -v
```

---

## 實戰範例：本專案操作

### 啟動開發環境

```bash
# 進入 VM
vagrant ssh

# 切換到專案目錄
cd /vagrant

# 啟動 DEV 環境
docker compose up -d

# 查看服務狀態
docker compose ps

# 查看日誌
docker compose logs -f
```

---

### 啟動 SIT 環境

```bash
cd /vagrant

# 啟動 SIT 環境 (共用 MySQL)
docker compose -f docker-compose.yml -f docker-compose.sit.yml up -d

# 查看服務
docker compose -f docker-compose.yml -f docker-compose.sit.yml ps

# 查看 SIT API 日誌
docker compose -f docker-compose.yml -f docker-compose.sit.yml logs -f api
```

---

### 資料庫操作

```bash
# 進入 MySQL 容器
docker compose exec mysql bash

# 連線 MySQL
docker compose exec mysql mysql -u root -p
# 輸入密碼: rootpassword

# 或直接執行 SQL
docker compose exec mysql mysql -u root -prootpassword -e "SHOW DATABASES;"

# 匯入 SQL
docker compose exec -T mysql mysql -u root -prootpassword graphqllab < backup.sql

# 匯出 SQL
docker compose exec mysql mysqldump -u root -prootpassword graphqllab > backup.sql
```

---

### 應用程式除錯

```bash
# 進入 API 容器
docker compose exec api bash

# 查看 Go 版本
docker compose exec api go version

# 查看環境變數
docker compose exec api env

# 查看配置檔
docker compose exec api cat config.yaml

# 重新建置並啟動
docker compose up -d --build api
```

---

### 完全重置環境

```bash
# 停止並刪除所有容器、網路、volumes
docker compose down -v

# 刪除 images (可選)
docker rmi $(docker images -q)

# 重新啟動
docker compose up -d
```

---

## 最佳實踐

### 1. 定期清理

```bash
# 每週執行
docker system prune -a
```

### 2. 使用 .dockerignore

```
.git/
.env
*.md
node_modules/
vendor/
*.log
```

### 3. 多階段建置 (Dockerfile)

```dockerfile
# Builder Stage
FROM golang:1.21 AS builder
WORKDIR /app
COPY . .
RUN go build -o main .

# Runtime Stage
FROM alpine:latest
COPY --from=builder /app/main .
CMD ["./main"]
```

### 4. 健康檢查

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1
```

### 5. 限制資源

```yaml
# docker-compose.yml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
```

---

## 故障排除

### 容器無法啟動

```bash
# 查看詳細日誌
docker logs container-name

# 查看容器退出原因
docker inspect -f '{{.State}}' container-name
```

### Port 衝突

```bash
# 查看 Port 佔用
sudo netstat -tulpn | grep 8080

# 修改 docker-compose.yml Port 映射
```

### Volume 權限問題

```bash
# 修改 Volume 權限
docker exec -u root container-name chown -R 1000:1000 /data
```

---

## 進階主題

### Docker Registry (私有映像倉庫)

```bash
# 登入 Docker Hub
docker login

# 推送 image
docker push username/my-app:1.0

# 私有 Registry
docker login registry.example.com
docker tag my-app:1.0 registry.example.com/my-app:1.0
docker push registry.example.com/my-app:1.0
```

### Docker Context (多環境管理)

```bash
# 列出 contexts
docker context ls

# 建立遠端 context
docker context create remote --docker "host=ssh://user@remote-server"

# 切換 context
docker context use remote

# 恢復本機
docker context use default
```

---

## 參考資源

- [Docker 官方文件](https://docs.docker.com/)
- [Docker Compose 文件](https://docs.docker.com/compose/)
- [Dockerfile 最佳實踐](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

---

## 下一步

- [COMPOSE_GUIDE.md](COMPOSE_GUIDE.md) - Docker Compose 進階指南
- [VOLUMES_NETWORKING.md](VOLUMES_NETWORKING.md) - Volumes 與網路深入解析

返回: [../../README.md](../../README.md)
