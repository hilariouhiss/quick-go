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
