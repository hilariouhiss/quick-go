package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"quick/internal/middleware"
	"quick/internal/response"
	"quick/internal/service"
)

type createUserRequest struct {
	Username   string   `json:"username" binding:"required,notblank,min=3,max=64"`
	Email      string   `json:"email" binding:"required,notblank,email,max=255"`
	UsedBy     string   `json:"used_by" binding:"max=64"`
	EmployeeNo string   `json:"employee_no" binding:"max=64"`
	Phone      string   `json:"phone" binding:"max=32"`
	Password   string   `json:"password" binding:"required,notblank,min=8,max=72"`
	Status     *int16   `json:"status" binding:"omitempty,oneof=0 1 2"`
	Roles      []string `json:"roles" binding:"omitempty,dive,required,notblank,max=64"`
}

type updateUserRequest struct {
	Username   string `json:"username" binding:"required,notblank,min=3,max=64"`
	Email      string `json:"email" binding:"required,notblank,email,max=255"`
	UsedBy     string `json:"used_by" binding:"max=64"`
	EmployeeNo string `json:"employee_no" binding:"max=64"`
	Phone      string `json:"phone" binding:"max=32"`
	Status     int16  `json:"status" binding:"oneof=0 1 2"`
}

type updateStatusRequest struct {
	Status int16 `json:"status" binding:"required,oneof=0 1 2"`
}

type updatePasswordRequest struct {
	Password string `json:"password" binding:"required,notblank,min=8,max=72"`
}

type setRolesRequest struct {
	Roles []string `json:"roles" binding:"omitempty,dive,required,notblank,max=64"`
}

func NewListUsersHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
		statusQuery := c.Query("status")
		var statusPtr *int16
		if statusQuery != "" {
			statusInt, err := strconv.Atoi(statusQuery)
			if err != nil {
				response.JSON(c, http.StatusBadRequest, "invalid request", nil)
				return
			}
			status := int16(statusInt)
			statusPtr = &status
		}
		data, err := userService.ListUsers(c.Request.Context(), service.ListUsersInput{
			Username: c.Query("username"),
			Status:   statusPtr,
			Page:     page,
			PageSize: pageSize,
		})
		if err != nil {
			response.JSON(c, http.StatusInternalServerError, "list users failed", nil)
			return
		}
		response.JSON(c, http.StatusOK, "ok", data)
	}
}

func NewGetUserHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		data, err := userService.GetUserByID(c.Request.Context(), userID)
		if err != nil {
			handleUserServiceError(c, err, "get user failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", data)
	}
}

func NewCreateUserHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		var req createUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		status := int16(1)
		if req.Status != nil {
			status = *req.Status
		}
		data, err := userService.CreateUser(c.Request.Context(), actorID, service.CreateUserInput{
			Username:   req.Username,
			Email:      req.Email,
			UsedBy:     req.UsedBy,
			EmployeeNo: req.EmployeeNo,
			Phone:      req.Phone,
			Password:   req.Password,
			Status:     status,
			Roles:      req.Roles,
		})
		if err != nil {
			handleUserServiceError(c, err, "create user failed")
			return
		}
		response.JSON(c, http.StatusCreated, "ok", data)
	}
}

func NewUpdateUserHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		var req updateUserRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		data, err := userService.UpdateUser(c.Request.Context(), actorID, userID, service.UpdateUserInput{
			Username:   req.Username,
			Email:      req.Email,
			UsedBy:     req.UsedBy,
			EmployeeNo: req.EmployeeNo,
			Phone:      req.Phone,
			Status:     req.Status,
		})
		if err != nil {
			handleUserServiceError(c, err, "update user failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", data)
	}
}

func NewUpdateUserStatusHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		var req updateStatusRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		data, err := userService.ChangeStatus(c.Request.Context(), actorID, userID, req.Status)
		if err != nil {
			handleUserServiceError(c, err, "update user status failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", data)
	}
}

func NewUpdateUserPasswordHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		var req updatePasswordRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		if err := userService.ChangePassword(c.Request.Context(), actorID, userID, req.Password); err != nil {
			handleUserServiceError(c, err, "update user password failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", gin.H{"user_id": userID})
	}
}

func NewSetUserRolesHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		var req setRolesRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			response.JSON(c, http.StatusBadRequest, "invalid request", nil)
			return
		}
		data, err := userService.SetRoles(c.Request.Context(), actorID, userID, req.Roles)
		if err != nil {
			handleUserServiceError(c, err, "set user roles failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", data)
	}
}

func NewDeleteUserHandler(userService *service.UserService) gin.HandlerFunc {
	return func(c *gin.Context) {
		actorID, ok := parseActorID(c)
		if !ok {
			return
		}
		userID, ok := parsePathID(c)
		if !ok {
			return
		}
		if err := userService.DeleteUser(c.Request.Context(), actorID, userID); err != nil {
			handleUserServiceError(c, err, "delete user failed")
			return
		}
		response.JSON(c, http.StatusOK, "ok", gin.H{"user_id": userID})
	}
}

func parsePathID(c *gin.Context) (int64, bool) {
	userID, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil || userID <= 0 {
		response.JSON(c, http.StatusBadRequest, "invalid request", nil)
		return 0, false
	}
	return userID, true
}

func parseActorID(c *gin.Context) (int64, bool) {
	actor, ok := c.Get(middleware.ContextUserIDKey)
	if !ok {
		response.JSON(c, http.StatusUnauthorized, "unauthorized", nil)
		return 0, false
	}
	switch value := actor.(type) {
	case int64:
		return value, true
	case int32:
		return int64(value), true
	case int:
		return int64(value), true
	case float64:
		return int64(value), true
	default:
		response.JSON(c, http.StatusUnauthorized, "unauthorized", nil)
		return 0, false
	}
}

func handleUserServiceError(c *gin.Context, err error, defaultMessage string) {
	switch {
	case errors.Is(err, service.ErrInvalidArgument):
		response.JSON(c, http.StatusBadRequest, "invalid request", nil)
	case errors.Is(err, service.ErrUserNotFound):
		response.JSON(c, http.StatusNotFound, "user not found", nil)
	case errors.Is(err, service.ErrUserConflict):
		response.JSON(c, http.StatusConflict, "username or email already exists", nil)
	case errors.Is(err, service.ErrRoleNotFound):
		response.JSON(c, http.StatusBadRequest, "role not found", nil)
	case errors.Is(err, service.ErrPermissionDeny):
		response.JSON(c, http.StatusForbidden, "forbidden", nil)
	default:
		response.JSON(c, http.StatusInternalServerError, defaultMessage, nil)
	}
}
