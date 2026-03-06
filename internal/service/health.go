package service

import "context"

// DBPinger 抽象数据库探活能力，便于替换与测试
type DBPinger interface {
	Ping(context.Context) error
}

// HealthService 提供系统健康检查能力
type HealthService struct {
	db DBPinger
}

// NewHealthService 创建健康检查服务
func NewHealthService(db DBPinger) *HealthService {
	return &HealthService{db: db}
}

// Status 返回健康状态并校验数据库连接
func (s *HealthService) Status(ctx context.Context) (string, error) {
	if s.db == nil {
		return "health check ok", nil
	}
	if err := s.db.Ping(ctx); err != nil {
		return "", err
	}
	return "health check ok", nil
}
