-- name: CreateRolePermission :one
INSERT INTO role_permissions (
    role_id,
    permission_id,
    created_by,
    updated_by,
    version
) SELECT
    $1,
    $2,
    $3,
    $4,
    1
WHERE EXISTS (
    SELECT 1
    FROM roles
    WHERE roles.id = $1
      AND roles.deleted_at IS NULL
)
  AND EXISTS (
    SELECT 1
    FROM permissions
    WHERE permissions.id = $2
      AND permissions.deleted_at IS NULL
)
  AND EXISTS (
    SELECT 1
    FROM users
    WHERE users.id = $3
      AND users.deleted_at IS NULL
)
  AND EXISTS (
    SELECT 1
    FROM users
    WHERE users.id = $4
      AND users.deleted_at IS NULL
)
RETURNING *;

-- name: GetActiveRolePermissionByRoleID :many
SELECT *
FROM role_permissions
WHERE role_id = $1
  AND deleted_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM roles
      WHERE roles.id = role_permissions.role_id
        AND roles.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM permissions
      WHERE permissions.id = role_permissions.permission_id
        AND permissions.deleted_at IS NULL
  );

-- name: UpdateActiveRolePermissionByID :one
UPDATE role_permissions
SET role_id = $2,
    permission_id = $3,
    updated_by = $4,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM roles
      WHERE roles.id = $2
        AND roles.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM permissions
      WHERE permissions.id = $3
        AND permissions.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM users
      WHERE users.id = $4
        AND users.deleted_at IS NULL
  )
RETURNING *;

-- name: SoftDeleteRolePermissionByID :one
UPDATE role_permissions
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: SoftDeleteRolePermissionsByRoleID :many
UPDATE role_permissions
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: RestoreSoftDeletedRolePermissionsByRoleID :many
UPDATE role_permissions
SET deleted_at = NULL,
    deleted_by = NULL,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NOT NULL
RETURNING *;
