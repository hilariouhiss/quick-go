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

func New(healthService *service.HealthService, authService *service.AuthService, userService *service.UserService) *gin.Engine {
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
	engine.POST("/auth/register", handler.NewRegisterHandler(authService))
	engine.POST("/auth/login", handler.NewLoginHandler(authService))
	engine.POST("/auth/refresh", handler.NewRefreshHandler(authService))
	protected := engine.Group("/")
	protected.Use(middleware.AuthRequired(authService))
	protected.GET("/auth/me", handler.CurrentUser)
	admin := engine.Group("/admin")
	admin.Use(middleware.AuthRequired(authService), middleware.RoleRequired("admin"))
	admin.GET("/users", handler.NewListUsersHandler(userService))
	admin.GET("/users/:id", handler.NewGetUserHandler(userService))
	admin.POST("/users", handler.NewCreateUserHandler(userService))
	admin.PUT("/users/:id", handler.NewUpdateUserHandler(userService))
	admin.PATCH("/users/:id/status", handler.NewUpdateUserStatusHandler(userService))
	admin.PATCH("/users/:id/password", handler.NewUpdateUserPasswordHandler(userService))
	admin.PUT("/users/:id/roles", handler.NewSetUserRolesHandler(userService))
	admin.DELETE("/users/:id", handler.NewDeleteUserHandler(userService))
	return engine
}
