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
