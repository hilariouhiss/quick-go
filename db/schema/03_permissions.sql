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
