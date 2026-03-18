package config

import (
	"errors"
	"os"
	"strings"

	"github.com/spf13/viper"
)

// Config 定义应用运行所需的核心配置
type Config struct {
	Env      string         `mapstructure:"env"`
	Addr     string         `mapstructure:"addr"`
	Postgres PostgresConfig `mapstructure:"postgres"`
	JWT      JWTConfig      `mapstructure:"jwt"`
}

// PostgresConfig 定义 PostgreSQL 连接与连接池参数
type PostgresConfig struct {
	DSN      string `mapstructure:"dsn"`
	User     string `mapstructure:"user"`
	Password string `mapstructure:"password"`
	Schema   string `mapstructure:"schema"`
	MaxConns int32  `mapstructure:"max_conns"`
	MinConns int32  `mapstructure:"min_conns"`
}

type JWTConfig struct {
	Secret           string `mapstructure:"secret"`
	Issuer           string `mapstructure:"issuer"`
	AccessTTLMinutes int64  `mapstructure:"access_ttl_minutes"`
	RefreshTTLHours  int64  `mapstructure:"refresh_ttl_hours"`
}

// Load 按环境加载配置，支持 dev/product 与环境变量覆盖
func Load() (Config, error) {
	v := viper.New()
	v.SetConfigType("yaml")
	v.AddConfigPath(".")
	v.AddConfigPath("./config")
	v.SetEnvPrefix("QUICK")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()
	env := normalizeEnv(os.Getenv("QUICK_ENV"))
	v.Set("env", env)
	v.SetConfigName("config." + env)
	v.SetDefault("addr", ":8080")
	v.SetDefault("env", env)
	switch env {
	case "dev":
		v.SetDefault("postgres.dsn", "postgres://localhost:5432/dev?sslmode=disable")
	case "product":
		v.SetDefault("postgres.dsn", "postgres://localhost:5432/product?sslmode=disable")
	}
	v.SetDefault("postgres.user", "")
	v.SetDefault("postgres.password", "")
	v.SetDefault("postgres.schema", "public")
	v.SetDefault("postgres.max_conns", 20)
	v.SetDefault("postgres.min_conns", 2)
	v.SetDefault("jwt.secret", "quick-dev-secret")
	v.SetDefault("jwt.issuer", "quick")
	v.SetDefault("jwt.access_ttl_minutes", int64(30))
	v.SetDefault("jwt.refresh_ttl_hours", int64(168))

	if err := v.ReadInConfig(); err != nil {
		var notFound viper.ConfigFileNotFoundError
		if !errors.As(err, &notFound) {
			return Config{}, err
		}
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return Config{}, err
	}
	cfg.Env = normalizeEnv(cfg.Env)
	return cfg, nil
}

// normalizeEnv 统一环境名称，非法值回退到 dev
func normalizeEnv(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "product", "prod", "production":
		return "product"
	default:
		return "dev"
	}
}
