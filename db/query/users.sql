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

-- name: GetActiveUserByID :one
SELECT *
FROM users
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetActiveUserByUsername :one
SELECT *
FROM users
WHERE username = $1
  AND deleted_at IS NULL;

-- name: ListActiveUsers :many
SELECT *
FROM users
WHERE deleted_at IS NULL
ORDER BY created_at DESC;

-- name: UpdateActiveUserByID :one
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

-- name: SoftDeleteUserAndUserRoles :one
WITH deleted_user AS (
    UPDATE users
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NULL
    RETURNING *
),
deleted_user_roles AS (
    UPDATE user_roles
    SET deleted_at = NOW(),
        deleted_by = $2,
        updated_by = $2,
        version = version + 1
    WHERE user_id = $1
      AND deleted_at IS NULL
    RETURNING id
)
SELECT *
FROM deleted_user;

-- name: GetSoftDeletedUserByID :one
SELECT *
FROM users
WHERE id = $1
  AND deleted_at IS NOT NULL;

-- name: GetSoftDeletedUserByUsername :one
SELECT *
FROM users
WHERE username = $1
  AND deleted_at IS NOT NULL;

-- name: ListSoftDeletedUsers :many
SELECT *
FROM users
WHERE deleted_at IS NOT NULL
ORDER BY deleted_at DESC;

-- name: RestoreUserAndUserRoles :one
WITH restored_user AS (
    UPDATE users
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE id = $1
      AND deleted_at IS NOT NULL
    RETURNING *
),
restored_user_roles AS (
    UPDATE user_roles
    SET deleted_at = NULL,
        deleted_by = NULL,
        updated_by = $2,
        version = version + 1
    WHERE user_id = $1
      AND deleted_at IS NOT NULL
    RETURNING id
)
SELECT *
FROM restored_user;
