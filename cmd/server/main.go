package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/yourusername/graphqllab/internal/config"
)

func main() {
	// Initialize database connection
	dbConfig := &config.DatabaseConfig{
		Host:     getEnv("DB_HOST", "localhost"),
		Port:     3306,
		User:     getEnv("DB_USER", "root"),
		Password: getEnv("DB_PASSWORD", "password"),
		DBName:   getEnv("DB_NAME", "graphqllab"),
		Charset:  "utf8mb4",
	}

	db, err := config.NewDatabaseConnection(dbConfig)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Test database connection
	if err := testDatabaseConnection(db); err != nil {
		log.Printf("Warning: Database test failed: %v", err)
	}

	// Setup HTTP routes
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, GraphQL Lab!")
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(); err != nil {
			w.WriteHeader(http.StatusServiceUnavailable)
			fmt.Fprintf(w, `{"status":"unhealthy","error":"%v"}`, err)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"healthy","database":"connected"}`)
	})

	// Start server
	port := ":" + getEnv("SERVER_PORT", "8080")
	log.Printf("Server starting on port %s", port)
	log.Printf("Health check available at http://localhost%s/health", port)
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatal(err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func testDatabaseConnection(db *sql.DB) error {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil {
		return fmt.Errorf("failed to query users table: %w", err)
	}
	log.Printf("Database test successful: Found %d users in database", count)
	return nil
}
