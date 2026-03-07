启动 PostgreSQL 容器：

```shell
docker run -d `
  --name postgres `
  -e POSTGRES_USER=dev `
  -e POSTGRES_PASSWORD=dev123 `
  -e POSTGRES_DB=dev` 
  -p 5432:5432 `
  -v pgdata:/var/lib/postgresql/data `
  --restart unless-stopped `
  postgres:18
```

启动 Redis 容器：

```shell
docker run -d `
--name redis `
-p 6379:6379 `
-v /data/redis:/data `
--restart unless-stopped `
redis:8.6.1 `
redis-server --appendonly yes --requirepass "dev123"
```