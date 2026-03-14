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
