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

-- name: GetUserRoleByID :one
SELECT *
FROM user_roles
WHERE id = $1
  AND deleted_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM users
      WHERE users.id = user_roles.user_id
        AND users.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM roles
      WHERE roles.id = user_roles.role_id
        AND roles.deleted_at IS NULL
  );

-- name: ListUserRoles :many
SELECT *
FROM user_roles
WHERE deleted_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM users
      WHERE users.id = user_roles.user_id
        AND users.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM roles
      WHERE roles.id = user_roles.role_id
        AND roles.deleted_at IS NULL
  )
ORDER BY created_at DESC;

-- name: UpdateUserRole :one
UPDATE user_roles
SET user_id = $2,
    role_id = $3,
    updated_by = $4,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
  AND EXISTS (
      SELECT 1
      FROM users
      WHERE users.id = $2
        AND users.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM roles
      WHERE roles.id = $3
        AND roles.deleted_at IS NULL
  )
  AND EXISTS (
      SELECT 1
      FROM users
      WHERE users.id = $4
        AND users.deleted_at IS NULL
  )
RETURNING *;

-- name: DeleteUserRole :one
UPDATE user_roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteUserRolesByUserID :many
UPDATE user_roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE user_id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: RestoreUserRolesByUserID :many
UPDATE user_roles
SET deleted_at = NULL,
    deleted_by = NULL,
    updated_by = $2,
    version = version + 1
WHERE user_id = $1
  AND deleted_at IS NOT NULL
RETURNING *;

-- name: DeleteUserRolesByRoleID :many
UPDATE user_roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: RestoreUserRolesByRoleID :many
UPDATE user_roles
SET deleted_at = NULL,
    deleted_by = NULL,
    updated_by = $2,
    version = version + 1
WHERE role_id = $1
  AND deleted_at IS NOT NULL
RETURNING *;
