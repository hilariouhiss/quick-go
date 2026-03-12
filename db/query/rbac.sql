-- name: CreateUser :one
INSERT INTO users (
    username,
    email,
    password_hash,
    status,
    created_by,
    updated_by,
    version
) VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    1
)
RETURNING *;

-- name: GetUserByID :one
SELECT *
FROM users
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListUsers :many
SELECT *
FROM users
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateUser :one
UPDATE users
SET username = $2,
    email = $3,
    password_hash = $4,
    status = $5,
    updated_by = $6,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteUser :one
UPDATE users
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

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

-- name: GetRoleByID :one
SELECT *
FROM roles
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListRoles :many
SELECT *
FROM roles
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateRole :one
UPDATE roles
SET code = $2,
    name = $3,
    description = $4,
    updated_by = $5,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteRole :one
UPDATE roles
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

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

-- name: GetPermissionByID :one
SELECT *
FROM permissions
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListPermissions :many
SELECT *
FROM permissions
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdatePermission :one
UPDATE permissions
SET resource = $2,
    action = $3,
    name = $4,
    updated_by = $5,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeletePermission :one
UPDATE permissions
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: CreateUserRole :one
INSERT INTO user_roles (
    user_id,
    role_id,
    created_by,
    updated_by,
    version
) VALUES (
    $1,
    $2,
    $3,
    $4,
    1
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

-- name: CreateRolePermission :one
INSERT INTO role_permissions (
    role_id,
    permission_id,
    created_by,
    updated_by,
    version
) VALUES (
    $1,
    $2,
    $3,
    $4,
    1
)
RETURNING *;

-- name: GetRolePermissionByID :one
SELECT *
FROM role_permissions
WHERE id = $1
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

-- name: ListRolePermissions :many
SELECT *
FROM role_permissions
WHERE deleted_at IS NULL
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
  )
ORDER BY created_at DESC;

-- name: UpdateRolePermission :one
UPDATE role_permissions
SET role_id = $2,
    permission_id = $3,
    updated_by = $4,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteRolePermission :one
UPDATE role_permissions
SET deleted_at = NOW(),
    deleted_by = $2,
    updated_by = $2,
    version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;
