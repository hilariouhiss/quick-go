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

