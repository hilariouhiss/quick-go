CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    username VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX users_username_unique_active_idx ON users (username) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX users_email_unique_active_idx ON users (email) WHERE deleted_at IS NULL;

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    code VARCHAR(64) NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX roles_code_unique_active_idx ON roles (code) WHERE deleted_at IS NULL;

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    name VARCHAR(128) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX permissions_resource_action_unique_active_idx ON permissions (resource, action) WHERE deleted_at IS NULL;

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX user_roles_user_role_unique_active_idx ON user_roles (user_id, role_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_user_id_active_idx ON user_roles (user_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_role_id_active_idx ON user_roles (role_id) WHERE deleted_at IS NULL;

CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX role_permissions_role_permission_unique_active_idx ON role_permissions (role_id, permission_id) WHERE deleted_at IS NULL;
CREATE INDEX role_permissions_role_id_active_idx ON role_permissions (role_id) WHERE deleted_at IS NULL;
CREATE INDEX role_permissions_permission_id_active_idx ON role_permissions (permission_id) WHERE deleted_at IS NULL;

COMMENT ON TABLE users IS '系统用户表';
COMMENT ON COLUMN users.id IS '主键，UUIDv7';
COMMENT ON COLUMN users.username IS '用户名，逻辑未删除范围内唯一';
COMMENT ON COLUMN users.email IS '邮箱，逻辑未删除范围内唯一';
COMMENT ON COLUMN users.password_hash IS '密码哈希';
COMMENT ON COLUMN users.is_active IS '账号是否启用';
COMMENT ON COLUMN users.created_at IS '创建时间';
COMMENT ON COLUMN users.updated_at IS '更新时间';
COMMENT ON COLUMN users.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE roles IS '角色表';
COMMENT ON COLUMN roles.id IS '主键，UUIDv7';
COMMENT ON COLUMN roles.code IS '角色编码，逻辑未删除范围内唯一';
COMMENT ON COLUMN roles.name IS '角色名称';
COMMENT ON COLUMN roles.description IS '角色描述';
COMMENT ON COLUMN roles.created_at IS '创建时间';
COMMENT ON COLUMN roles.updated_at IS '更新时间';
COMMENT ON COLUMN roles.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE permissions IS '权限点表';
COMMENT ON COLUMN permissions.id IS '主键，UUIDv7';
COMMENT ON COLUMN permissions.resource IS '资源标识，例如 user、project';
COMMENT ON COLUMN permissions.action IS '动作标识，例如 read、write、delete';
COMMENT ON COLUMN permissions.name IS '权限名称';
COMMENT ON COLUMN permissions.created_at IS '创建时间';
COMMENT ON COLUMN permissions.updated_at IS '更新时间';
COMMENT ON COLUMN permissions.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE user_roles IS '用户与角色关联表';
COMMENT ON COLUMN user_roles.id IS '主键，UUIDv7';
COMMENT ON COLUMN user_roles.user_id IS '用户ID';
COMMENT ON COLUMN user_roles.role_id IS '角色ID';
COMMENT ON COLUMN user_roles.created_at IS '创建时间';
COMMENT ON COLUMN user_roles.updated_at IS '更新时间';
COMMENT ON COLUMN user_roles.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE role_permissions IS '角色与权限关联表';
COMMENT ON COLUMN role_permissions.id IS '主键，UUIDv7';
COMMENT ON COLUMN role_permissions.role_id IS '角色ID';
COMMENT ON COLUMN role_permissions.permission_id IS '权限ID';
COMMENT ON COLUMN role_permissions.created_at IS '创建时间';
COMMENT ON COLUMN role_permissions.updated_at IS '更新时间';
COMMENT ON COLUMN role_permissions.deleted_at IS '逻辑删除时间，NULL 表示未删除';
