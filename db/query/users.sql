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
