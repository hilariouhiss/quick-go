package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"quick/internal/response"
	"quick/internal/service"
)

const (
	ContextUserIDKey   = "auth.user_id"
	ContextUsernameKey = "auth.username"
	ContextRolesKey    = "auth.roles"
)

func AuthRequired(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractBearerToken(c.GetHeader("Authorization"))
		if token == "" {
			response.JSON(c, http.StatusUnauthorized, "missing authorization token", nil)
			c.Abort()
			return
		}
		claims, err := authService.VerifyAccessToken(token)
		if err != nil {
			if err == service.ErrTokenExpired {
				response.JSON(c, http.StatusUnauthorized, "token expired", nil)
				c.Abort()
				return
			}
			response.JSON(c, http.StatusUnauthorized, "token invalid", nil)
			c.Abort()
			return
		}
		c.Set(ContextUserIDKey, claims.UserID)
		c.Set(ContextUsernameKey, claims.Username)
		c.Set(ContextRolesKey, claims.Roles)
		c.Next()
	}
}

func extractBearerToken(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}
	const prefix = "Bearer "
	if len(value) <= len(prefix) || !strings.EqualFold(value[:len(prefix)], prefix) {
		return ""
	}
	return strings.TrimSpace(value[len(prefix):])
}
