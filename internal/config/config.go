package config

type Config struct {
	Addr string
}

// Load 加载配置
func Load() Config {
	return Config{
		Addr: ":8080",
	}
}
