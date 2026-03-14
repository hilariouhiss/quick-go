-- name: CreatePermission :one
INSERT INTO permissions (
    resource,
    action,
    name,
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

-- name: GetActivePermissionByID :one
SELECT *
FROM permissions
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListActivePermissions :many
SELECT *
FROM permissions
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateActivePermissionByID :one
UPDATE permissions
SET resource = $2,
    action = $3,
    name = $4,
    updated_by = $5,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeletePermissionByID :one
UPDATE permissions
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;
