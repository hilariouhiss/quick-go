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
