package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/yourusername/graphqllab/internal/config"
	"github.com/yourusername/graphqllab/internal/model"
)

func main() {
	// 自動載入配置
	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	log.Printf("=== GraphQL Lab Starting ===")
	log.Printf("Environment: %s", cfg.Environment)
	log.Printf("Server Mode: %s", cfg.Server.Mode)
	log.Printf("Log Level: %s", cfg.Logging.Level)

	// 連接資料庫
	db, err := config.NewDatabaseConnection(&cfg.Database)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// 首頁
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "GraphQL Lab - Environment: %s", cfg.Environment)
	})

	// 健康檢查
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(map[string]string{
				"status": "unhealthy",
				"error":  err.Error(),
			})
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"status":      "healthy",
			"environment": cfg.Environment,
			"database":    "connected",
		})
	})

	// 取得所有使用者（簡單查詢）
	http.HandleFunc("/users", func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Query("SELECT id, name, email, age, created_at FROM users ORDER BY id")
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
			return
		}
		defer rows.Close()

		var users []*model.User
		for rows.Next() {
			user := &model.User{}
			if err := rows.Scan(&user.ID, &user.Name, &user.Email, &user.Age, &user.CreatedAt); err != nil {
				w.WriteHeader(http.StatusInternalServerError)
				json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
				return
			}
			users = append(users, user)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(users)
	})

	// GraphQL playground（待實作）
	if cfg.GraphQL.PlaygroundEnabled {
		http.HandleFunc(cfg.GraphQL.Playground, func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "GraphQL Playground (Coming Soon)")
		})
		log.Printf("GraphQL Playground: http://localhost:%d%s", cfg.Server.Port, cfg.GraphQL.Playground)
	}

	// 啟動伺服器
	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)
	log.Printf("Server: http://localhost:%d", cfg.Server.Port)
	log.Printf("Health: http://localhost:%d/health", cfg.Server.Port)
	log.Printf("Users:  http://localhost:%d/users", cfg.Server.Port)

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}
