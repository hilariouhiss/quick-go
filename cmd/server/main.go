package main

import (
	"log"

	"quick/internal/app"
	"quick/internal/config"
)

// main 启动 HTTP 服务入口
func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("配置加载失败: %v", err)
		return
	}
	// 创建并启动应用
	application := app.New(cfg)
	err = application.Run()
	if err != nil {
		log.Fatalf("服务启动失败: %v", err)
		return
	}
}
