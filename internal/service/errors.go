package service

import (
	"errors"

	"github.com/jackc/pgx/v5/pgconn"
)

var (
	ErrInvalidArgument = errors.New("invalid argument")
	ErrUserNotFound    = errors.New("user not found")
	ErrUserConflict    = errors.New("user conflict")
	ErrRoleNotFound    = errors.New("role not found")
	ErrPermissionDeny  = errors.New("permission denied")
)

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
