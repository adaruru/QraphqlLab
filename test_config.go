package main

import (
	"fmt"
	"log"
	"os"

	"github.com/yourusername/graphqllab/internal/config"
)

func main() {
	// 測試不同環境的配置載入
	environments := []string{"development", "sit"}

	for _, env := range environments {
		os.Setenv("APP_ENV", env)

		cfg, err := config.LoadConfig()
		if err != nil {
			log.Fatalf("Failed to load config for %s: %v", env, err)
		}

		fmt.Printf("\n=== Environment: %s ===\n", env)
		fmt.Printf("Environment Field: %s\n", cfg.Environment)
		fmt.Printf("Database Host: %s\n", cfg.Database.Host)
		fmt.Printf("Database Port: %d\n", cfg.Database.Port)
		fmt.Printf("Database User: %s\n", cfg.Database.User)
		fmt.Printf("Database Name: %s\n", cfg.Database.Name)
		fmt.Printf("Server Port: %d\n", cfg.Server.Port)
		fmt.Printf("Server Mode: %s\n", cfg.Server.Mode)
		fmt.Printf("Log Level: %s\n", cfg.Logging.Level)
		fmt.Printf("GraphQL Playground: %s (enabled: %v)\n",
			cfg.GraphQL.Playground, cfg.GraphQL.PlaygroundEnabled)
	}

	// 測試環境變數覆蓋
	fmt.Printf("\n=== Testing Environment Variable Override ===\n")
	os.Setenv("APP_ENV", "development")
	os.Setenv("DB_HOST", "custom-mysql-host")
	os.Setenv("DB_PORT", "3307")

	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	fmt.Printf("Database Host (should be custom-mysql-host): %s\n", cfg.Database.Host)
	fmt.Printf("Database Port (should be 3307): %d\n", cfg.Database.Port)
}
