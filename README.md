| 功能模块          | 推荐技术栈                                                             | 版本/仓库     | 选择理由                                                         | 避坑提示                              |
|---------------|-------------------------------------------------------------------|-----------|--------------------------------------------------------------|-----------------------------------|
| JWT 认证        | `github.com/golang-jwt/jwt/v5`                                    | v5.2.0+   | 社区官方维护（原 dgrijalva/jwt-go fork），支持 HS256/RS256，Go Modules 友好 | ❌ 避免 `dgrijalva/jwt-go`（2021 年归档） |
| RBAC 权限       | `github.com/casbin/casbin/v2` + `github.com/casbin/gin-casbin/v2` | v2.70.0+  | 策略热加载、支持 DB/File 适配器、Gin 中间件开箱即用                             | ❌ 避免手写 RBAC（易漏边界、难维护）             |
| 全局错误处理        | 自定义中间件 + `github.com/getsentry/sentry-go`                         | v0.25.0+  | 捕获 panic + 业务错误分级处理，Sentry 实时告警                              | 必须设置 `gin.Recovery()` 基础防护        |
| 统一响应          | 自定义 `Response` 结构体 + 辅助函数                                         | -         | 轻量可控，避免第三方库耦合                                                | 示例见下方代码片段                         |
| 结构化日志         | `go.uber.org/zap` + `github.com/gin-contrib/zap`                  | v1.26.0+  | 性能碾压 logrus（10x+），JSON 格式，Gin 中间件集成                          | ❌ 避免 `logrus`（维护停滞）               |
| Redis 客户端     | `github.com/redis/go-redis/v9`                                    | v9.5.0+   | 官方维护（原 go-redis/redis 迁移），支持 Cluster/Sentinel/Pipeline       | ❌ 避免 `redigo`（无连接池优化）             |
| PostgreSQL 驱动 | `github.com/jackc/pgx/v5`（直接使用）                                   | v5.5.0+   | 专为 PG 优化，性能 > database/sql + pq，支持连接池/批量操作                   | ❌ 避免 `lib/pq`（2023 年归档）           |
| 参数校验          | `github.com/go-playground/validator/v10`                          | v10.18.0+ | Gin 默认集成，自定义校验标签，多语言错误翻译                                     | 与 `binding` 标签无缝配合                |
| 配置管理          | `github.com/spf13/viper` + 环境变量                                   | v1.18.0+  | 支持 YAML/JSON/ENV，热重载（需自定义）                                   | 敏感信息通过 K8s Secret / Vault 注入      |

## Users RESTful + PostgreSQL（按当前结构落地）

### 目录规划

```
cmd/server/main.go
internal/app/app.go
internal/config/config.go
internal/router/router.go
internal/handler/user.go
internal/service/user.go
internal/repository/user_repository.go
internal/repository/user_pg.go
internal/model/user.go
```

### 1）Model

`internal/model/user.go`

```go
package model

type User struct {
	ID    int64  `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}
```

### 2）Repository 接口

`internal/repository/user_repository.go`

```go
package repository

import "quick/internal/model"

type UserRepository interface {
	Create(name, email string) (model.User, error)
	GetByID(id int64) (model.User, error)
	List() ([]model.User, error)
}
```

### 3）PostgreSQL 实现

`internal/repository/user_pg.go`

```go
package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
	"quick/internal/model"
)

type UserRepoPG struct {
	DB *pgxpool.Pool
}

func NewUserRepoPG(db *pgxpool.Pool) *UserRepoPG {
	return &UserRepoPG{DB: db}
}

func (r *UserRepoPG) Create(name, email string) (model.User, error) {
	var u model.User
	err := r.DB.QueryRow(context.Background(),
		"insert into users(name,email) values($1,$2) returning id,name,email",
		name, email,
	).Scan(&u.ID, &u.Name, &u.Email)
	return u, err
}

func (r *UserRepoPG) GetByID(id int64) (model.User, error) {
	var u model.User
	err := r.DB.QueryRow(context.Background(),
		"select id,name,email from users where id=$1",
		id,
	).Scan(&u.ID, &u.Name, &u.Email)
	return u, err
}

func (r *UserRepoPG) List() ([]model.User, error) {
	rows, err := r.DB.Query(context.Background(),
		"select id,name,email from users order by id desc",
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []model.User
	for rows.Next() {
		var u model.User
		if err := rows.Scan(&u.ID, &u.Name, &u.Email); err != nil {
			return nil, err
		}
		list = append(list, u)
	}
	return list, rows.Err()
}
```

### 4）Service 层

`internal/service/user.go`

```go
package service

import (
	"quick/internal/model"
	"quick/internal/repository"
)

type UserService struct {
	Repo repository.UserRepository
}

func NewUserService(repo repository.UserRepository) *UserService {
	return &UserService{Repo: repo}
}

func (s *UserService) CreateUser(name, email string) (model.User, error) {
	return s.Repo.Create(name, email)
}

func (s *UserService) GetUser(id int64) (model.User, error) {
	return s.Repo.GetByID(id)
}

func (s *UserService) ListUsers() ([]model.User, error) {
	return s.Repo.List()
}
```

### 5）Handler 层

`internal/handler/user.go`

```go
package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"quick/internal/response"
	"quick/internal/service"
)

type UserHandler struct {
	Svc *service.UserService
}

func NewUserHandler(svc *service.UserService) *UserHandler {
	return &UserHandler{Svc: svc}
}

func (h *UserHandler) List(c *gin.Context) {
	users, err := h.Svc.ListUsers()
	if err != nil {
		response.JSON(c, http.StatusInternalServerError, "list users failed", nil)
		return
	}
	response.JSON(c, http.StatusOK, "ok", users)
}

func (h *UserHandler) Get(c *gin.Context) {
	id, _ := strconv.ParseInt(c.Param("id"), 10, 64)
	user, err := h.Svc.GetUser(id)
	if err != nil {
		response.JSON(c, http.StatusNotFound, "user not found", nil)
		return
	}
	response.JSON(c, http.StatusOK, "ok", user)
}

func (h *UserHandler) Create(c *gin.Context) {
	var req struct {
		Name  string `json:"name"`
		Email string `json:"email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.JSON(c, http.StatusBadRequest, "invalid request", nil)
		return
	}
	user, err := h.Svc.CreateUser(req.Name, req.Email)
	if err != nil {
		response.JSON(c, http.StatusInternalServerError, "create user failed", nil)
		return
	}
	response.JSON(c, http.StatusOK, "ok", user)
}
```

### 6）路由注册

`internal/router/router.go`

```go
userRepo := repository.NewUserRepoPG(db)
userService := service.NewUserService(userRepo)
userHandler := handler.NewUserHandler(userService)

api := engine.Group("/api")
users := api.Group("/users")
users.GET("", userHandler.List)
users.GET("/:id", userHandler.Get)
users.POST("", userHandler.Create)
```

### 7）数据库配置与初始化

`internal/config/config.go` 增加数据库连接参数，在 `internal/app/app.go` 中创建 pgxpool 并注入
`repository.NewUserRepoPG`。

### 8）建议的表结构

```sql
create table if not exists users
(
    id
    bigserial
    primary
    key,
    name
    text
    not
    null,
    email
    text
    not
    null
    unique
);
```

