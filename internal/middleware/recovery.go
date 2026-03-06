package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"quick/internal/response"
)

// Recovery 捕获 panic 并返回统一错误响应
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				// 对外返回统一格式，避免泄露内部错误细节
				response.JSON(c, http.StatusInternalServerError, "internal server error", nil)
				c.Abort()
			}
		}()
		c.Next()
	}
}
