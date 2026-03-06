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
		// 复用请求上下文，避免健康检查阻塞退出流程
		status, err := svc.Status(c.Request.Context())
		if err != nil {
			response.JSON(c, http.StatusServiceUnavailable, "database unavailable", nil)
			return
		}
		response.JSON(c, http.StatusOK, status, "")
	}
}
