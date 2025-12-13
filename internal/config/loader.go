package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"gopkg.in/yaml.v3"
)

// Config 應用程式完整配置結構
type Config struct {
	Environment string         `yaml:"environment"`
	Database    DatabaseConfig `yaml:"database"`
	Server      ServerConfig   `yaml:"server"`
	Logging     LoggingConfig  `yaml:"logging"`
	GraphQL     GraphQLConfig  `yaml:"graphql"`
	Features    FeaturesConfig `yaml:"features"`
}

// ServerConfig 伺服器配置
type ServerConfig struct {
	Port         int           `yaml:"port"`
	Host         string        `yaml:"host"`
	Mode         string        `yaml:"mode"`
	ReadTimeout  time.Duration `yaml:"read_timeout"`
	WriteTimeout time.Duration `yaml:"write_timeout"`
	IdleTimeout  time.Duration `yaml:"idle_timeout"`
}

// LoggingConfig 日誌配置
type LoggingConfig struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
}

// GraphQLConfig GraphQL 配置
type GraphQLConfig struct {
	Endpoint          string `yaml:"endpoint"`
	Playground        string `yaml:"playground"`
	PlaygroundEnabled bool   `yaml:"playground_enabled"`
}

// FeaturesConfig 功能開關配置
type FeaturesConfig struct {
	EnableGraphQL bool `yaml:"enable_graphql"`
	EnableREST    bool `yaml:"enable_rest"`
}

// LoadConfig 自動根據 APP_ENV 環境變數載入對應的配置檔案
// 預設為 development 環境
//
// 配置載入策略：
// 1. 先載入 config.yaml (基礎配置)
// 2. 如果是非 development 環境，載入環境專屬配置並合併
// 3. 應用環境變數覆蓋
func LoadConfig() (*Config, error) {
	env := getEnv("APP_ENV", "development")

	// 1. 載入基礎配置 config.yaml
	baseConfig, err := loadYAMLFile("config.yaml")
	if err != nil {
		return nil, fmt.Errorf("failed to load base config: %w", err)
	}

	// 2. 如果不是 development，載入環境專屬配置並合併
	if env != "development" {
		envConfigFile := getConfigFile(env)
		if envConfigFile != "config.yaml" {
			envConfig, err := loadYAMLFile(envConfigFile)
			if err != nil {
				return nil, fmt.Errorf("failed to load env config %s: %w", envConfigFile, err)
			}
			// 合併配置：環境配置覆蓋基礎配置
			mergeConfig(baseConfig, envConfig)
		}
	}

	// 3. 應用環境變數覆蓋
	applyEnvironmentOverrides(baseConfig)

	return baseConfig, nil
}

// getConfigFile 根據環境返回對應的配置檔案路徑
func getConfigFile(env string) string {
	configMap := map[string]string{
		"development": "config.yaml",
		"sit":         "config.sit.yaml",
		"uat":         "config.uat.yaml",
		"production":  "config.prod.yaml",
	}

	if file, ok := configMap[env]; ok {
		return file
	}

	// 預設返回 development 配置
	return "config.yaml"
}

// loadYAMLFile 載入 YAML 配置檔案
func loadYAMLFile(filename string) (*Config, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", filename, err)
	}

	var config Config
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse yaml config: %w", err)
	}

	return &config, nil
}

// applyEnvironmentOverrides 使用環境變數覆蓋 YAML 配置
// 優先順序：環境變數 > YAML 配置
func applyEnvironmentOverrides(cfg *Config) {
	// Database 覆蓋
	if v := os.Getenv("DB_HOST"); v != "" {
		cfg.Database.Host = v
	}
	if v := os.Getenv("DB_PORT"); v != "" {
		if port, err := strconv.Atoi(v); err == nil {
			cfg.Database.Port = port
		}
	}
	if v := os.Getenv("DB_USER"); v != "" {
		cfg.Database.User = v
	}
	if v := os.Getenv("DB_PASSWORD"); v != "" {
		cfg.Database.Password = v
	}
	if v := os.Getenv("DB_NAME"); v != "" {
		cfg.Database.Name = v
	}

	// Server 覆蓋
	if v := os.Getenv("SERVER_PORT"); v != "" {
		if port, err := strconv.Atoi(v); err == nil {
			cfg.Server.Port = port
		}
	}
	if v := os.Getenv("SERVER_HOST"); v != "" {
		cfg.Server.Host = v
	}
	if v := os.Getenv("GIN_MODE"); v != "" {
		cfg.Server.Mode = v
	}

	// Logging 覆蓋
	if v := os.Getenv("LOG_LEVEL"); v != "" {
		cfg.Logging.Level = v
	}
}

// mergeConfig 將 override 配置合併到 base 配置
// 只覆蓋 override 中有值的欄位
func mergeConfig(base, override *Config) {
	// Environment
	if override.Environment != "" {
		base.Environment = override.Environment
	}

	// Database - 只覆蓋非零值
	if override.Database.Host != "" {
		base.Database.Host = override.Database.Host
	}
	if override.Database.Port != 0 {
		base.Database.Port = override.Database.Port
	}
	if override.Database.User != "" {
		base.Database.User = override.Database.User
	}
	if override.Database.Password != "" {
		base.Database.Password = override.Database.Password
	}
	if override.Database.Name != "" {
		base.Database.Name = override.Database.Name
	}
	if override.Database.Charset != "" {
		base.Database.Charset = override.Database.Charset
	}
	if override.Database.MaxOpenConnections != 0 {
		base.Database.MaxOpenConnections = override.Database.MaxOpenConnections
	}
	if override.Database.MaxIdleConnections != 0 {
		base.Database.MaxIdleConnections = override.Database.MaxIdleConnections
	}
	if override.Database.ConnectionMaxLifetime != 0 {
		base.Database.ConnectionMaxLifetime = override.Database.ConnectionMaxLifetime
	}

	// Server
	if override.Server.Port != 0 {
		base.Server.Port = override.Server.Port
	}
	if override.Server.Host != "" {
		base.Server.Host = override.Server.Host
	}
	if override.Server.Mode != "" {
		base.Server.Mode = override.Server.Mode
	}
	if override.Server.ReadTimeout != 0 {
		base.Server.ReadTimeout = override.Server.ReadTimeout
	}
	if override.Server.WriteTimeout != 0 {
		base.Server.WriteTimeout = override.Server.WriteTimeout
	}
	if override.Server.IdleTimeout != 0 {
		base.Server.IdleTimeout = override.Server.IdleTimeout
	}

	// Logging
	if override.Logging.Level != "" {
		base.Logging.Level = override.Logging.Level
	}
	if override.Logging.Format != "" {
		base.Logging.Format = override.Logging.Format
	}

	// GraphQL
	if override.GraphQL.Endpoint != "" {
		base.GraphQL.Endpoint = override.GraphQL.Endpoint
	}
	if override.GraphQL.Playground != "" {
		base.GraphQL.Playground = override.GraphQL.Playground
	}
	// bool 型態需要特殊處理，因為 false 也是有效值
	// 這裡我們假設如果 override 有設定，就覆蓋
	base.GraphQL.PlaygroundEnabled = override.GraphQL.PlaygroundEnabled

	// Features
	base.Features.EnableGraphQL = override.Features.EnableGraphQL
	base.Features.EnableREST = override.Features.EnableREST
}

// getEnv 取得環境變數，如果不存在則返回預設值
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
