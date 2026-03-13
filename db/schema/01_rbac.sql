CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash CHAR(60) NOT NULL,
    status SMALLINT NOT NULL DEFAULT 1,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    deleted_by BIGINT,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

ALTER TABLE users
    ADD CONSTRAINT users_status_check CHECK (status IN (0, 1, 2)),
    ADD CONSTRAINT users_deleted_audit_check CHECK ((deleted_at IS NULL) = (deleted_by IS NULL));

CREATE UNIQUE INDEX users_username_unique_active_idx ON users (username) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX users_email_unique_active_idx ON users (email) WHERE deleted_at IS NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM users
        WHERE id = 1
          AND username <> 'system'
    ) THEN
        RAISE EXCEPTION 'seed conflict: id=1 is occupied by non-system user';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM users
        WHERE username = 'system'
          AND id <> 1
    ) THEN
        RAISE EXCEPTION 'seed conflict: username=system exists with id <> 1';
    END IF;

    INSERT INTO users (id, username, email, password_hash, status, created_by, updated_by)
    OVERRIDING SYSTEM VALUE
    VALUES (1, 'system', 'system@local', '$2a$10$.hvirm.kuybwWCyFmryCY.6Vkn968pSO93gzwz.OsrYAvexU2wZ2i', 0, 1, 1)
    -- system.account.disabled.password.placeholder
    ON CONFLICT (id) DO UPDATE
    SET username = EXCLUDED.username,
        email = EXCLUDED.email,
        password_hash = EXCLUDED.password_hash,
        status = EXCLUDED.status,
        created_by = EXCLUDED.created_by,
        updated_by = EXCLUDED.updated_by,
        deleted_by = NULL,
        deleted_at = NULL;
END;
$$;

SELECT setval(
    pg_get_serial_sequence('users', 'id'),
    (SELECT MAX(id) FROM users),
    true
);

ALTER TABLE users
    ADD CONSTRAINT users_created_by_fkey
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT users_updated_by_fkey
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT users_deleted_by_fkey
        FOREIGN KEY (deleted_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE TABLE roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(64) NOT NULL,
    name VARCHAR(128) NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    deleted_by BIGINT,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

ALTER TABLE roles
    ADD CONSTRAINT roles_deleted_audit_check CHECK ((deleted_at IS NULL) = (deleted_by IS NULL));

CREATE UNIQUE INDEX roles_code_unique_active_idx ON roles (code) WHERE deleted_at IS NULL;

ALTER TABLE roles
    ADD CONSTRAINT roles_created_by_fkey
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT roles_updated_by_fkey
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT roles_deleted_by_fkey
        FOREIGN KEY (deleted_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE TABLE permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    name VARCHAR(128) NOT NULL,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    deleted_by BIGINT,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

ALTER TABLE permissions
    ADD CONSTRAINT permissions_deleted_audit_check CHECK ((deleted_at IS NULL) = (deleted_by IS NULL));

CREATE UNIQUE INDEX permissions_resource_action_unique_active_idx ON permissions (resource, action) WHERE deleted_at IS NULL;

ALTER TABLE permissions
    ADD CONSTRAINT permissions_created_by_fkey
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT permissions_updated_by_fkey
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT permissions_deleted_by_fkey
        FOREIGN KEY (deleted_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE TABLE user_roles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    deleted_by BIGINT,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
ALTER TABLE user_roles
    ADD CONSTRAINT user_roles_deleted_audit_check CHECK ((deleted_at IS NULL) = (deleted_by IS NULL));

ALTER TABLE user_roles
    ADD CONSTRAINT user_roles_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users (id),
    ADD CONSTRAINT user_roles_role_id_fkey
        FOREIGN KEY (role_id) REFERENCES roles (id),
    ADD CONSTRAINT user_roles_created_by_fkey
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT user_roles_updated_by_fkey
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT user_roles_deleted_by_fkey
        FOREIGN KEY (deleted_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE UNIQUE INDEX user_roles_user_role_unique_active_idx ON user_roles (user_id, role_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_user_id_active_idx ON user_roles (user_id) WHERE deleted_at IS NULL;
CREATE INDEX user_roles_role_id_active_idx ON user_roles (role_id) WHERE deleted_at IS NULL;

CREATE TABLE role_permissions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    updated_by BIGINT NOT NULL,
    deleted_by BIGINT,
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);
ALTER TABLE role_permissions
    ADD CONSTRAINT role_permissions_deleted_audit_check CHECK ((deleted_at IS NULL) = (deleted_by IS NULL));

ALTER TABLE role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey
        FOREIGN KEY (role_id) REFERENCES roles (id),
    ADD CONSTRAINT role_permissions_permission_id_fkey
        FOREIGN KEY (permission_id) REFERENCES permissions (id),
    ADD CONSTRAINT role_permissions_created_by_fkey
        FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT role_permissions_updated_by_fkey
        FOREIGN KEY (updated_by) REFERENCES users (id) ON DELETE RESTRICT,
    ADD CONSTRAINT role_permissions_deleted_by_fkey
        FOREIGN KEY (deleted_by) REFERENCES users (id) ON DELETE SET NULL;

CREATE UNIQUE INDEX role_permissions_role_permission_unique_active_idx ON role_permissions (role_id, permission_id) WHERE deleted_at IS NULL;
CREATE INDEX role_permissions_role_id_active_idx ON role_permissions (role_id) WHERE deleted_at IS NULL;
CREATE INDEX role_permissions_permission_id_active_idx ON role_permissions (permission_id) WHERE deleted_at IS NULL;

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER roles_set_updated_at
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER permissions_set_updated_at
    BEFORE UPDATE ON permissions
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER user_roles_set_updated_at
    BEFORE UPDATE ON user_roles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER role_permissions_set_updated_at
    BEFORE UPDATE ON role_permissions
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

COMMENT ON TABLE users IS '系统用户表';
COMMENT ON COLUMN users.id IS '主键，自增ID';
COMMENT ON COLUMN users.username IS '用户名，逻辑未删除范围内唯一';
COMMENT ON COLUMN users.email IS '邮箱，逻辑未删除范围内唯一';
COMMENT ON COLUMN users.password_hash IS '密码哈希';
COMMENT ON COLUMN users.status IS '账号状态：0 disabled，1 active，2 locked';
COMMENT ON COLUMN users.created_by IS '创建人ID';
COMMENT ON COLUMN users.updated_by IS '更新人ID';
COMMENT ON COLUMN users.deleted_by IS '删除人ID';
COMMENT ON COLUMN users.version IS '乐观锁版本号';
COMMENT ON COLUMN users.created_at IS '创建时间';
COMMENT ON COLUMN users.updated_at IS '更新时间';
COMMENT ON COLUMN users.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE roles IS '角色表';
COMMENT ON COLUMN roles.id IS '主键，自增ID';
COMMENT ON COLUMN roles.code IS '角色编码，逻辑未删除范围内唯一';
COMMENT ON COLUMN roles.name IS '角色名称';
COMMENT ON COLUMN roles.description IS '角色描述';
COMMENT ON COLUMN roles.created_by IS '创建人ID';
COMMENT ON COLUMN roles.updated_by IS '更新人ID';
COMMENT ON COLUMN roles.deleted_by IS '删除人ID';
COMMENT ON COLUMN roles.version IS '乐观锁版本号';
COMMENT ON COLUMN roles.created_at IS '创建时间';
COMMENT ON COLUMN roles.updated_at IS '更新时间';
COMMENT ON COLUMN roles.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE permissions IS '权限点表';
COMMENT ON COLUMN permissions.id IS '主键，自增ID';
COMMENT ON COLUMN permissions.resource IS '资源标识，例如 user、project';
COMMENT ON COLUMN permissions.action IS '动作标识，例如 read、write、delete';
COMMENT ON COLUMN permissions.name IS '权限名称';
COMMENT ON COLUMN permissions.created_by IS '创建人ID';
COMMENT ON COLUMN permissions.updated_by IS '更新人ID';
COMMENT ON COLUMN permissions.deleted_by IS '删除人ID';
COMMENT ON COLUMN permissions.version IS '乐观锁版本号';
COMMENT ON COLUMN permissions.created_at IS '创建时间';
COMMENT ON COLUMN permissions.updated_at IS '更新时间';
COMMENT ON COLUMN permissions.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE user_roles IS '用户与角色关联表';
COMMENT ON COLUMN user_roles.id IS '主键，自增ID';
COMMENT ON COLUMN user_roles.user_id IS '用户ID';
COMMENT ON COLUMN user_roles.role_id IS '角色ID';
COMMENT ON COLUMN user_roles.created_by IS '创建人ID';
COMMENT ON COLUMN user_roles.updated_by IS '更新人ID';
COMMENT ON COLUMN user_roles.deleted_by IS '删除人ID';
COMMENT ON COLUMN user_roles.version IS '乐观锁版本号';
COMMENT ON COLUMN user_roles.created_at IS '创建时间';
COMMENT ON COLUMN user_roles.updated_at IS '更新时间';
COMMENT ON COLUMN user_roles.deleted_at IS '逻辑删除时间，NULL 表示未删除';

COMMENT ON TABLE role_permissions IS '角色与权限关联表';
COMMENT ON COLUMN role_permissions.id IS '主键，自增ID';
COMMENT ON COLUMN role_permissions.role_id IS '角色ID';
COMMENT ON COLUMN role_permissions.permission_id IS '权限ID';
COMMENT ON COLUMN role_permissions.created_by IS '创建人ID';
COMMENT ON COLUMN role_permissions.updated_by IS '更新人ID';
COMMENT ON COLUMN role_permissions.deleted_by IS '删除人ID';
COMMENT ON COLUMN role_permissions.version IS '乐观锁版本号';
COMMENT ON COLUMN role_permissions.created_at IS '创建时间';
COMMENT ON COLUMN role_permissions.updated_at IS '更新时间';
COMMENT ON COLUMN role_permissions.deleted_at IS '逻辑删除时间，NULL 表示未删除';
