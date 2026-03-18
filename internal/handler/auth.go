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

type registerRequest struct {
	Username   string `json:"username" binding:"required,notblank,min=3,max=64"`
	Email      string `json:"email" binding:"required,notblank,email,max=255"`
	Password   string `json:"password" binding:"required,notblank,min=8,max=72"`
	UsedBy     string `json:"used_by" binding:"max=64"`
	EmployeeNo string `json:"employee_no" binding:"max=64"`
	Phone      string `json:"phone" binding:"max=32"`
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

func NewRegisterHandler(authService *service.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req registerRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		created, err := authService.Register(c.Request.Context(), service.RegisterInput{
			Username:   req.Username,
			Email:      req.Email,
			Password:   req.Password,
			UsedBy:     req.UsedBy,
			EmployeeNo: req.EmployeeNo,
			Phone:      req.Phone,
		})
		if err != nil {
			switch {
			case errors.Is(err, service.ErrInvalidArgument):
				response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			case errors.Is(err, service.ErrUserConflict):
				response.JSON(c, http.StatusConflict, "username or email already exists", nil)
			default:
				response.JSON(c, http.StatusInternalServerError, "register failed", nil)
			}
			return
		}
		response.JSON(c, http.StatusCreated, "ok", created)
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
