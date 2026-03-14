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
