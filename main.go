package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	//  "github.com/golang-jwt/jwt/v5"
	//  ginzap "github.com/gin-contrib/zap"
	//  "go.uber.org/zap"
	//	"github.com/redis/go-redis/v9"
	//	"github.com/jackc/pgx/v5"
	//	"github.com/go-playground/validator/v10"
)

type Response struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"` // 无数据时自动省略该字段
}

func jsonResponse(c *gin.Context, code int, message string, data any) {
	c.JSON(http.StatusOK, Response{
		Code:    code,
		Message: message,
		Data:    data,
	})
}

func main() {
	router := gin.Default()
	router.Use(func(c *gin.Context) {
		defer func() {
			if r := recover(); r != nil {
				jsonResponse(c, http.StatusInternalServerError, "internal server error", nil)
				c.Abort()
			}
		}()
		c.Next()
	})
	router.GET("/health", func(c *gin.Context) {
		jsonResponse(c, http.StatusOK, "health check ok", "")
	})
	// TODO：设置为 Nginx IP 地址
	err := router.Run()
	if err != nil {
		log.Fatalf("服务启动失败: %v", err)
		return
	}
}
