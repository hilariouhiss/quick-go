-- name: CreateUser :one
INSERT INTO users (
    username,
    email,
    password_hash,
    is_active
) VALUES (
    $1,
    $2,
    $3,
    $4
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
    is_active = $5,
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteUser :one
UPDATE users
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: CreateRole :one
INSERT INTO roles (
    code,
    name,
    description
) VALUES (
    $1,
    $2,
    $3
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
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteRole :one
UPDATE roles
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: CreatePermission :one
INSERT INTO permissions (
    resource,
    action,
    name
) VALUES (
    $1,
    $2,
    $3
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
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeletePermission :one
UPDATE permissions
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: CreateUserRole :one
INSERT INTO user_roles (
    user_id,
    role_id
) VALUES (
    $1,
    $2
)
RETURNING *;

-- name: GetUserRoleByID :one
SELECT *
FROM user_roles
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListUserRoles :many
SELECT *
FROM user_roles
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateUserRole :one
UPDATE user_roles
SET user_id = $2,
    role_id = $3,
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteUserRole :one
UPDATE user_roles
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: CreateRolePermission :one
INSERT INTO role_permissions (
    role_id,
    permission_id
) VALUES (
    $1,
    $2
)
RETURNING *;

-- name: GetRolePermissionByID :one
SELECT *
FROM role_permissions
WHERE id = $1
  AND deleted_at IS NULL;

-- name: ListRolePermissions :many
SELECT *
FROM role_permissions
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateRolePermission :one
UPDATE role_permissions
SET role_id = $2,
    permission_id = $3,
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;

-- name: DeleteRolePermission :one
UPDATE role_permissions
SET deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;
