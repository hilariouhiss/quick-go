package service

type HealthService struct{}

// NewHealthService 创建健康检查服务
func NewHealthService() *HealthService {
	return &HealthService{}
}

// Status 返回健康状态
func (s *HealthService) Status() string {
	return "health check ok"
}
