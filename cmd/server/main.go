package main

import (
	"context"
	"log"

	"quick/internal/app"
	"quick/internal/config"
)

// main 启动 HTTP 服务入口
func main() {
	// 读取环境配置（含 dev/product 切换逻辑）
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("配置加载失败: %v", err)
		return
	}
	// 构建应用并初始化基础设施（数据库连接池、路由等）
	application, err := app.New(context.Background(), cfg)
	if err != nil {
		log.Fatalf("应用初始化失败: %v", err)
		return
	}
	// 进程退出时优雅释放基础设施资源
	defer application.Close()
	// 启动 HTTP 服务
	err = application.Run()
	if err != nil {
		log.Fatalf("服务启动失败: %v", err)
		return
	}
}
