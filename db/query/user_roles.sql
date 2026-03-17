-- name: CreateUserRole :one
INSERT INTO user_roles (
    user_id,
    role_id,
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
    FROM users
    WHERE users.id = $1
      AND users.deleted_at IS NULL
)
  AND EXISTS (
    SELECT 1
    FROM roles
    WHERE roles.id = $2
      AND roles.deleted_at IS NULL
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

-- name: GetActiveUserRolesByUserId :many
SELECT * 
FROM user_roles
WHERE user_id = $1
  AND deleted_at IS NULL;

-- name: SoftDeleteUserRolesByUserId :many
UPDATE user_roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE user_id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: RestoreSoftDeletedUserRolesByUserId :many
UPDATE user_roles
SET deleted_at = NULL,
    deleted_by = NULL,
    updated_by = $2,
    version = version + 1
WHERE user_id = $1
  AND deleted_at IS NOT NULL
RETURNING *;

-- name: SoftDeleteUserRolesByRoleId :many
UPDATE user_roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: RestoreSoftDeletedUserRolesByRoleId :many
UPDATE user_roles
SET deleted_at = NULL,
    deleted_by = NULL,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NOT NULL
RETURNING *;
