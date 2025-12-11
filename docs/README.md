# GraphQL Lab 文件中心

本目錄包含 GraphQL Lab 專案的所有技術文件。

## 📚 文件索引

### 🚀 快速開始

| 文件 | 說明 | 閱讀時間 |
|------|------|---------|
| [QUICK_START_ENVIRONMENTS.md](../QUICK_START_ENVIRONMENTS.md) | 快速啟動各環境指南 | 5 分鐘 |
| [DOCKER_SETUP.md](../DOCKER_SETUP.md) | Docker 快速參考 | 10 分鐘 |

### 📖 完整指南

| 文件 | 說明 | 閱讀時間 |
|------|------|---------|
| [ENVIRONMENT_CONFIG.md](../ENVIRONMENT_CONFIG.md) | 環境配置完整說明 | 30 分鐘 |
| [CONFIG_VS_ENV.md](CONFIG_VS_ENV.md) | Config vs Env 深度解析 | 30 分鐘 |

### 🎯 決策參考

| 文件 | 說明 | 閱讀時間 |
|------|------|---------|
| [CONFIG_DECISION_TREE.md](CONFIG_DECISION_TREE.md) | 配置決策樹與實例 | 15 分鐘 |
| [config.detailed.example.yaml](../config.detailed.example.yaml) | 詳細註解的配置範例 | 20 分鐘 |

### 📋 任務總結

| 文件 | 說明 |
|------|------|
| [TASK_0003_SUMMARY.md](TASK_0003_SUMMARY.md) | Task 0003 系列完成總結 |

## 🗂️ 按主題分類

### Docker 相關
- [DOCKER_SETUP.md](../DOCKER_SETUP.md) - Docker 基礎設定
- [ENVIRONMENT_CONFIG.md](../ENVIRONMENT_CONFIG.md) - 多環境 Docker 配置
- [QUICK_START_ENVIRONMENTS.md](../QUICK_START_ENVIRONMENTS.md) - 環境啟動指南

### 配置管理
- [CONFIG_VS_ENV.md](CONFIG_VS_ENV.md) - 配置管理哲學
- [CONFIG_DECISION_TREE.md](CONFIG_DECISION_TREE.md) - 配置決策指南
- [config.detailed.example.yaml](../config.detailed.example.yaml) - 配置範例

### 資料庫
- [infra/dbinit/README.md](../infra/dbinit/README.md) - 資料庫初始化指南

## 📝 使用建議

### 新手上路
1. 閱讀 [QUICK_START_ENVIRONMENTS.md](../QUICK_START_ENVIRONMENTS.md)
2. 執行 `./scripts/start-dev.sh` 啟動環境
3. 測試 `curl http://localhost:8080/health`

### 深入學習
1. 閱讀 [CONFIG_VS_ENV.md](CONFIG_VS_ENV.md) 理解配置哲學
2. 閱讀 [ENVIRONMENT_CONFIG.md](../ENVIRONMENT_CONFIG.md) 學習環境管理
3. 閱讀 [CONFIG_DECISION_TREE.md](CONFIG_DECISION_TREE.md) 學會決策

### 實作開發
1. 參考 [config.detailed.example.yaml](../config.detailed.example.yaml)
2. 查閱 [DOCKER_SETUP.md](../DOCKER_SETUP.md)
3. 參考 [infra/dbinit/README.md](../infra/dbinit/README.md)

## 🔑 核心概念速查

### 環境變數 vs 配置檔案

```
使用環境變數 (.env):
├─ 🔐 敏感資訊（密碼、金鑰）
├─ 🌐 環境特定值（主機名、Port）
└─ 🎚️ 運行模式（debug/release）

使用配置檔案 (config.yaml):
├─ ⚙️ 業務邏輯設定
├─ 🎯 功能開關
└─ 📏 固定參數
```

### 環境對照

| 環境 | Port | 資料庫 | 啟動方式 |
|------|------|--------|---------|
| DEV | 8080 | graphqllab | `./scripts/start-dev.sh` |
| SIT | 8081 | graphqllab_sit | `./scripts/start-sit.sh` |
| UAT | 8082 | graphqllab_uat | `./scripts/start-uat.sh` |

### 配置優先順序

```
環境變數 > .env 檔案 > config.yaml > 程式碼預設值
```

## 🛠️ 工具與腳本

### 啟動腳本位置
```
scripts/
├── start-dev.sh / start-dev.bat    # 開發環境
├── start-sit.sh / start-sit.bat    # SIT 環境
├── start-uat.sh / start-uat.bat    # UAT 環境
└── test-docker.sh                   # Docker 測試
```

### 配置檔案位置
```
根目錄/
├── .env                  # 開發環境（不提交）
├── .env.sit             # SIT 環境（不提交）
├── .env.uat             # UAT 環境（不提交）
├── .env.prod            # 正式環境（不提交）
├── config.example.yaml   # 配置範例（提交）
└── config.detailed.example.yaml  # 詳細範例（提交）
```

## 🔍 常見問題

### Q: 如何切換環境？
```bash
# Linux/macOS
./scripts/start-sit.sh

# Windows
scripts\start-sit.bat
```

### Q: 如何同時運行多個環境？
```bash
./scripts/start-dev.sh  # Port 8080
./scripts/start-sit.sh  # Port 8081
./scripts/start-uat.sh  # Port 8082
```

### Q: 配置應該放在哪裡？
查看 [CONFIG_DECISION_TREE.md](CONFIG_DECISION_TREE.md)

### Q: 如何管理敏感資訊？
查看 [CONFIG_VS_ENV.md](CONFIG_VS_ENV.md) 的「安全性」章節

## 📞 需要幫助？

1. 查閱相關文件（見上方索引）
2. 檢查 [TASK_0003_SUMMARY.md](TASK_0003_SUMMARY.md) 瞭解系統架構
3. 參考 [config.detailed.example.yaml](../config.detailed.example.yaml) 中的註解

## 📈 文件更新記錄

| 日期 | 文件 | 說明 |
|------|------|------|
| 2024-12 | CONFIG_VS_ENV.md | 新增 Config vs Env 深度解析 |
| 2024-12 | CONFIG_DECISION_TREE.md | 新增配置決策樹 |
| 2024-12 | ENVIRONMENT_CONFIG.md | 新增環境配置指南 |
| 2024-12 | TASK_0003_SUMMARY.md | Task 0003 系列完成總結 |

---

**提示：** 所有文件都包含豐富的範例和說明，建議循序漸進閱讀。
