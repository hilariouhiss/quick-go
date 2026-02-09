package app

import (
	"quick/internal/config"
	"quick/internal/router"
)

type App struct {
	Config config.Config
	Router *routerAdapter
}

type routerAdapter struct {
	engineHandler interface {
		Run(...string) error
	}
}

// New 创建应用实例并装配路由
func New(cfg config.Config) *App {
	engine := router.New()
	return &App{
		Config: cfg,
		Router: &routerAdapter{engineHandler: engine},
	}
}

// Run 启动 HTTP 服务
func (a *App) Run() error {
	return a.Router.engineHandler.Run(a.Config.Addr)
}
