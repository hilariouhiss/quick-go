package router

import (
	"github.com/gin-gonic/gin"

	"quick/internal/handler"
	"quick/internal/middleware"
	"quick/internal/service"
)

// New 创建并装配路由
func New() *gin.Engine {
	engine := gin.New()
	engine.Use(gin.Logger())
	engine.Use(middleware.Recovery())
	healthService := service.NewHealthService()
	engine.GET("/health", handler.NewHealthHandler(healthService))
	return engine
}
