package handler

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"quick/internal/middleware"
	"quick/internal/response"
	"quick/internal/service"
)

type loginRequest struct {
	Username string `json:"username" binding:"required,notblank"`
	Password string `json:"password" binding:"required,notblank"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required,notblank"`
}

func NewLoginHandler(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req loginRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		tokens, err := authService.Login(c.Request.Context(), req.Username, req.Password)
		if err != nil {
			if errors.Is(err, service.ErrInvalidCredentials) || errors.Is(err, service.ErrUserDisabled) {
				response.JSON(c, http.StatusUnauthorized, "username or password incorrect", nil)
				return
			}
			response.JSON(c, http.StatusInternalServerError, "login failed", nil)
			return
		}
		response.JSON(c, http.StatusOK, "ok", tokens)
	}
}

func NewRefreshHandler(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req refreshRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		tokens, err := authService.Refresh(c.Request.Context(), req.RefreshToken)
		if err != nil {
			switch {
			case errors.Is(err, service.ErrTokenExpired):
				response.JSON(c, http.StatusUnauthorized, "refresh token expired", nil)
			case errors.Is(err, service.ErrTokenInvalid), errors.Is(err, service.ErrInvalidCredentials), errors.Is(err, service.ErrUserDisabled):
				response.JSON(c, http.StatusUnauthorized, "refresh token invalid", nil)
			default:
				response.JSON(c, http.StatusInternalServerError, "refresh failed", nil)
			}
			return
		}
		response.JSON(c, http.StatusOK, "ok", tokens)
	}
}

func CurrentUser(c *gin.Context) {
	userID, _ := c.Get(middleware.ContextUserIDKey)
	username, _ := c.Get(middleware.ContextUsernameKey)
	roles, _ := c.Get(middleware.ContextRolesKey)
	response.JSON(c, http.StatusOK, "ok", gin.H{
		"user_id":  userID,
		"username": username,
		"roles":    roles,
	})
}
