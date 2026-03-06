package router

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"

	"quick/internal/handler"
	"quick/internal/middleware"
	"quick/internal/service"
)

// New 创建并装配路由
func New(healthService *service.HealthService) *gin.Engine {
	if v, ok := binding.Validator.Engine().(*validator.Validate); ok {
		_ = v.RegisterValidation("notblank", func(fl validator.FieldLevel) bool {
			value, ok := fl.Field().Interface().(string)
			if !ok {
				return false
			}
			return strings.TrimSpace(value) != ""
		})
	}

	engine := gin.New()
	engine.Use(gin.Logger())
	engine.Use(middleware.Recovery())
	engine.GET("/health", handler.NewHealthHandler(healthService))
	return engine
}
