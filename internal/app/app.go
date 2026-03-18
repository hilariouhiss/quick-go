package app

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"quick/internal/config"
	"quick/internal/infra"
	"quick/internal/router"
	"quick/internal/service"
)

// App 聚合应用运行时所需的核心依赖
type App struct {
	Config config.Config
	Router *routerAdapter
	DB     *pgxpool.Pool
}

type routerAdapter struct {
	engineHandler interface {
		Run(...string) error
	}
}

// New 创建应用实例并完成依赖装配
func New(ctx context.Context, cfg config.Config) (*App, error) {
	db, err := infra.NewPostgresPool(ctx, cfg.Postgres)
	if err != nil {
		return nil, err
	}
	jwtService, err := service.NewJWTService(cfg.JWT)
	if err != nil {
		db.Close()
		return nil, err
	}
	healthService := service.NewHealthService(db)
	authService := service.NewAuthService(db, jwtService)
	engine := router.New(healthService, authService)
	return &App{
		Config: cfg,
		Router: &routerAdapter{engineHandler: engine},
		DB:     db,
	}, nil
}

// Run 启动 HTTP 服务
func (a *App) Run() error {
	return a.Router.engineHandler.Run(a.Config.Addr)
}

// Close 释放应用持有的资源
func (a *App) Close() {
	if a.DB != nil {
		a.DB.Close()
	}
}
