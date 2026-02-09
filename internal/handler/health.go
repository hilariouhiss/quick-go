package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"quick/internal/response"
	"quick/internal/service"
)

// NewHealthHandler 返回健康检查处理器
func NewHealthHandler(svc *service.HealthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		response.JSON(c, http.StatusOK, svc.Status(), "")
	}
}
