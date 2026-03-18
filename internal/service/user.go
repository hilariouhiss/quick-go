package service

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	db *pgxpool.Pool
}

type UserView struct {
	ID         int64     `json:"id"`
	Username   string    `json:"username"`
	Email      string    `json:"email"`
	UsedBy     string    `json:"used_by"`
	EmployeeNo string    `json:"employee_no"`
	Phone      string    `json:"phone"`
	Status     int16     `json:"status"`
	Roles      []string  `json:"roles"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type UserListResult struct {
	Items    []UserView `json:"items"`
	Total    int64      `json:"total"`
	Page     int        `json:"page"`
	PageSize int        `json:"page_size"`
}

type ListUsersInput struct {
	Username string
	Status   *int16
	Page     int
	PageSize int
}

type CreateUserInput struct {
	Username   string
	Email      string
	UsedBy     string
	EmployeeNo string
	Phone      string
	Password   string
	Status     int16
	Roles      []string
}

type UpdateUserInput struct {
	Username   string
	Email      string
	UsedBy     string
	EmployeeNo string
	Phone      string
	Status     int16
}

func NewUserService(db *pgxpool.Pool) *UserService {
	return &UserService{db: db}
}

func (s *UserService) ListUsers(ctx context.Context, input ListUsersInput) (UserListResult, error) {
	page := input.Page
	pageSize := input.PageSize
	if page <= 0 {
		page = 1
	}
	if pageSize <= 0 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	username := strings.TrimSpace(input.Username)
	var statusArg any
	if input.Status != nil {
		statusArg = *input.Status
	}
	result := UserListResult{
		Items:    make([]UserView, 0),
		Page:     page,
		PageSize: pageSize,
	}
	countRow := s.db.QueryRow(ctx, `
SELECT COUNT(1)
FROM users u
WHERE u.deleted_at IS NULL
  AND ($1 = '' OR u.username ILIKE '%' || $1 || '%')
  AND ($2::smallint IS NULL OR u.status = $2)
`, username, statusArg)
	if err := countRow.Scan(&result.Total); err != nil {
		return UserListResult{}, err
	}
	rows, err := s.db.Query(ctx, `
SELECT
	u.id,
	u.username,
	u.email,
	u.used_by,
	u.employee_no,
	u.phone,
	u.status,
	COALESCE(array_agg(DISTINCT r.code ORDER BY r.code) FILTER (WHERE r.code IS NOT NULL), '{}') AS roles,
	u.created_at,
	u.updated_at
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id AND ur.deleted_at IS NULL
LEFT JOIN roles r ON r.id = ur.role_id AND r.deleted_at IS NULL
WHERE u.deleted_at IS NULL
  AND ($1 = '' OR u.username ILIKE '%' || $1 || '%')
  AND ($2::smallint IS NULL OR u.status = $2)
GROUP BY u.id
ORDER BY u.created_at DESC
LIMIT $3 OFFSET $4
`, username, statusArg, pageSize, (page-1)*pageSize)
	if err != nil {
		return UserListResult{}, err
	}
	defer rows.Close()
	for rows.Next() {
		item := UserView{}
		if scanErr := rows.Scan(
			&item.ID,
			&item.Username,
			&item.Email,
			&item.UsedBy,
			&item.EmployeeNo,
			&item.Phone,
			&item.Status,
			&item.Roles,
			&item.CreatedAt,
			&item.UpdatedAt,
		); scanErr != nil {
			return UserListResult{}, scanErr
		}
		result.Items = append(result.Items, item)
	}
	if rowsErr := rows.Err(); rowsErr != nil {
		return UserListResult{}, rowsErr
	}
	return result, nil
}

func (s *UserService) GetUserByID(ctx context.Context, userID int64) (UserView, error) {
	return fetchUserByID(ctx, s.db, userID)
}

func (s *UserService) CreateUser(ctx context.Context, actorID int64, input CreateUserInput) (UserView, error) {
	username := strings.TrimSpace(input.Username)
	email := strings.TrimSpace(input.Email)
	password := strings.TrimSpace(input.Password)
	if username == "" || email == "" || password == "" || !validUserStatus(input.Status) {
		return UserView{}, ErrInvalidArgument
	}
	roles, err := normalizeRoles(input.Roles)
	if err != nil {
		return UserView{}, err
	}
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return UserView{}, err
	}
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return UserView{}, err
	}
	defer tx.Rollback(ctx)
	var userID int64
	row := tx.QueryRow(ctx, `
INSERT INTO users (
	username,
	email,
	used_by,
	employee_no,
	phone,
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
	$7,
	$8,
	$8,
	1
)
RETURNING id
`, username, email, strings.TrimSpace(input.UsedBy), strings.TrimSpace(input.EmployeeNo), strings.TrimSpace(input.Phone), string(passwordHash), input.Status, actorID)
	if err = row.Scan(&userID); err != nil {
		if isUniqueViolation(err) {
			return UserView{}, ErrUserConflict
		}
		return UserView{}, err
	}
	if err = replaceUserRoles(ctx, tx, userID, actorID, roles); err != nil {
		return UserView{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return UserView{}, err
	}
	return s.GetUserByID(ctx, userID)
}

func (s *UserService) UpdateUser(ctx context.Context, actorID int64, userID int64, input UpdateUserInput) (UserView, error) {
	username := strings.TrimSpace(input.Username)
	email := strings.TrimSpace(input.Email)
	if userID <= 0 || username == "" || email == "" || !validUserStatus(input.Status) {
		return UserView{}, ErrInvalidArgument
	}
	row := s.db.QueryRow(ctx, `
UPDATE users
SET username = $2,
	email = $3,
	used_by = $4,
	employee_no = $5,
	phone = $6,
	status = $7,
	updated_by = $8,
	version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING id
`, userID, username, email, strings.TrimSpace(input.UsedBy), strings.TrimSpace(input.EmployeeNo), strings.TrimSpace(input.Phone), input.Status, actorID)
	var updatedID int64
	if err := row.Scan(&updatedID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return UserView{}, ErrUserNotFound
		}
		if isUniqueViolation(err) {
			return UserView{}, ErrUserConflict
		}
		return UserView{}, err
	}
	return s.GetUserByID(ctx, updatedID)
}

func (s *UserService) ChangeStatus(ctx context.Context, actorID int64, userID int64, status int16) (UserView, error) {
	if userID <= 0 || !validUserStatus(status) {
		return UserView{}, ErrInvalidArgument
	}
	row := s.db.QueryRow(ctx, `
UPDATE users
SET status = $2,
	updated_by = $3,
	version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
RETURNING id
`, userID, status, actorID)
	var updatedID int64
	if err := row.Scan(&updatedID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return UserView{}, ErrUserNotFound
		}
		return UserView{}, err
	}
	return s.GetUserByID(ctx, updatedID)
}

func (s *UserService) ChangePassword(ctx context.Context, actorID int64, userID int64, password string) error {
	password = strings.TrimSpace(password)
	if userID <= 0 || password == "" {
		return ErrInvalidArgument
	}
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	commandTag, err := s.db.Exec(ctx, `
UPDATE users
SET password_hash = $2,
	updated_by = $3,
	version = version + 1
WHERE id = $1
  AND deleted_at IS NULL
`, userID, string(passwordHash), actorID)
	if err != nil {
		return err
	}
	if commandTag.RowsAffected() == 0 {
		return ErrUserNotFound
	}
	return nil
}

func (s *UserService) SetRoles(ctx context.Context, actorID int64, userID int64, roles []string) (UserView, error) {
	if userID <= 0 {
		return UserView{}, ErrInvalidArgument
	}
	roleCodes, err := normalizeRoles(roles)
	if err != nil {
		return UserView{}, err
	}
	tx, err := s.db.Begin(ctx)
	if err != nil {
		return UserView{}, err
	}
	defer tx.Rollback(ctx)
	var existsID int64
	if err = tx.QueryRow(ctx, `
SELECT id
FROM users
WHERE id = $1
  AND deleted_at IS NULL
`, userID).Scan(&existsID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return UserView{}, ErrUserNotFound
		}
		return UserView{}, err
	}
	if err = replaceUserRoles(ctx, tx, userID, actorID, roleCodes); err != nil {
		return UserView{}, err
	}
	if err = tx.Commit(ctx); err != nil {
		return UserView{}, err
	}
	return s.GetUserByID(ctx, userID)
}

func (s *UserService) DeleteUser(ctx context.Context, actorID int64, userID int64) error {
	if userID <= 0 {
		return ErrInvalidArgument
	}
	if userID == 1 {
		return ErrPermissionDeny
	}
	row := s.db.QueryRow(ctx, `
WITH deleted_user AS (
	UPDATE users
	SET deleted_at = NOW(),
		deleted_by = $2,
		updated_by = $2,
		version = version + 1
	WHERE id = $1
	  AND deleted_at IS NULL
	RETURNING id
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
SELECT id
FROM deleted_user
`, userID, actorID)
	var deletedID int64
	if err := row.Scan(&deletedID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrUserNotFound
		}
		return err
	}
	return nil
}

type userQuerier interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func fetchUserByID(ctx context.Context, querier userQuerier, userID int64) (UserView, error) {
	if userID <= 0 {
		return UserView{}, ErrInvalidArgument
	}
	row := querier.QueryRow(ctx, `
SELECT
	u.id,
	u.username,
	u.email,
	u.used_by,
	u.employee_no,
	u.phone,
	u.status,
	COALESCE(array_agg(DISTINCT r.code ORDER BY r.code) FILTER (WHERE r.code IS NOT NULL), '{}') AS roles,
	u.created_at,
	u.updated_at
FROM users u
LEFT JOIN user_roles ur ON ur.user_id = u.id AND ur.deleted_at IS NULL
LEFT JOIN roles r ON r.id = ur.role_id AND r.deleted_at IS NULL
WHERE u.id = $1
  AND u.deleted_at IS NULL
GROUP BY u.id
`, userID)
	item := UserView{}
	if err := row.Scan(
		&item.ID,
		&item.Username,
		&item.Email,
		&item.UsedBy,
		&item.EmployeeNo,
		&item.Phone,
		&item.Status,
		&item.Roles,
		&item.CreatedAt,
		&item.UpdatedAt,
	); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return UserView{}, ErrUserNotFound
		}
		return UserView{}, err
	}
	return item, nil
}

func replaceUserRoles(ctx context.Context, tx pgx.Tx, userID int64, actorID int64, roles []string) error {
	if _, err := tx.Exec(ctx, `
UPDATE user_roles
SET deleted_at = NOW(),
	deleted_by = $2,
	updated_by = $2,
	version = version + 1
WHERE user_id = $1
  AND deleted_at IS NULL
`, userID, actorID); err != nil {
		return err
	}
	if len(roles) == 0 {
		return nil
	}
	commandTag, err := tx.Exec(ctx, `
INSERT INTO user_roles (
	user_id,
	role_id,
	created_by,
	updated_by,
	version
)
SELECT
	$1,
	r.id,
	$2,
	$2,
	1
FROM roles r
WHERE r.code = ANY($3)
  AND r.deleted_at IS NULL
`, userID, actorID, roles)
	if err != nil {
		return err
	}
	if int(commandTag.RowsAffected()) != len(roles) {
		return ErrRoleNotFound
	}
	return nil
}

func normalizeRoles(roles []string) ([]string, error) {
	if len(roles) == 0 {
		return nil, nil
	}
	dedup := make(map[string]struct{}, len(roles))
	result := make([]string, 0, len(roles))
	for _, role := range roles {
		code := strings.TrimSpace(role)
		if code == "" {
			return nil, ErrInvalidArgument
		}
		if _, ok := dedup[code]; ok {
			continue
		}
		dedup[code] = struct{}{}
		result = append(result, code)
	}
	return result, nil
}

func validUserStatus(status int16) bool {
	return status == 0 || status == 1 || status == 2
}
