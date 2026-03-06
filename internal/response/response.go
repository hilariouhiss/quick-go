package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Response 定义统一的 API 返回结构
type Response struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

// JSON 返回统一响应结构
func JSON(c *gin.Context, code int, message string, data any) {
	c.JSON(http.StatusOK, Response{
		Code:    code,
		Message: message,
		Data:    data,
	})
}
