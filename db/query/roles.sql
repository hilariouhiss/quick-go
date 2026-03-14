-- name: CreateRole :one
INSERT INTO roles (
    code,
    name,
    description,
    created_by,
    updated_by,
    version
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    1
)
RETURNING *;

-- name: GetActiveRoleByID :one
SELECT *
FROM roles
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListActiveRoles :many
SELECT *
FROM roles
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateActiveRoleByID :one
UPDATE roles
SET code = $2,
    name = $3,
    description = $4,
    updated_by = $5,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeleteRoleAndRolePermissions :one
WITH deleted_role AS (
    UPDATE roles
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NULL
    RETURNING *
),
deleted_role_permissions AS (
    UPDATE role_permissions
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NULL
    RETURNING id
)
SELECT *
FROM deleted_role;

-- name: SoftDeleteRoleAndRolePermissionsAndUserRoles :one
WITH deleted_role AS (
    UPDATE roles
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NULL
    RETURNING *
),
deleted_role_permissions AS (
    UPDATE role_permissions
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NULL
    RETURNING id
),
deleted_user_roles AS (
    UPDATE user_roles
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NULL
    RETURNING id
)
SELECT *
FROM deleted_role;

-- name: RestoreRoleAndRolePermissions :one
WITH restored_role AS (
    UPDATE roles
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NOT NULL
    RETURNING *
),
restored_role_permissions AS (
    UPDATE role_permissions
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NOT NULL
    RETURNING id
)
SELECT *
FROM restored_role;

-- name: RestoreRoleAndRolePermissionsAndUserRoles :one
WITH restored_role AS (
    UPDATE roles
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NOT NULL
    RETURNING *
),
restored_role_permissions AS (
    UPDATE role_permissions
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NOT NULL
    RETURNING id
),
restored_user_roles AS (
    UPDATE user_roles
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE role_id = $1
      AND deleted_at IS NOT NULL
    RETURNING id
)
SELECT *
FROM restored_role;
