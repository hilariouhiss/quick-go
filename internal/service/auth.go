package service

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrUserDisabled       = errors.New("user disabled")
)

type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int64  `json:"expires_in"`
}

type RegisterInput struct {
	Username   string
	Email      string
	Password   string
	UsedBy     string
	EmployeeNo string
	Phone      string
}

type RegisterResult struct {
	UserID   int64  `json:"user_id"`
	Username string `json:"username"`
	Email    string `json:"email"`
}

type AuthService struct {
	db         *pgxpool.Pool
	jwtService *JWTService
}

func NewAuthService(db *pgxpool.Pool, jwtService *JWTService) *AuthService {
	return &AuthService{
		db:         db,
		jwtService: jwtService,
	}
}

func (s *AuthService) Login(ctx context.Context, username string, password string) (TokenPair, error) {
	username = strings.TrimSpace(username)
	if username == "" || password == "" {
		return TokenPair{}, ErrInvalidCredentials
	}
	var (
		userID       int64
		dbUsername   string
		passwordHash string
		status       int16
	)
	// TODO: 不使用硬编码，改为sqlc生成的代码
	row := s.db.QueryRow(ctx, `
SELECT id, username, password_hash, status
FROM users
WHERE username = $1
  AND deleted_at IS NULL
`, username)
	if err := row.Scan(&userID, &dbUsername, &passwordHash, &status); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return TokenPair{}, ErrInvalidCredentials
		}
		return TokenPair{}, err
	}
	if status != 1 {
		return TokenPair{}, ErrUserDisabled
	}
	if err := bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(password)); err != nil {
		return TokenPair{}, ErrInvalidCredentials
	}
	roles, err := s.listRoles(ctx, userID)
	if err != nil {
		return TokenPair{}, err
	}
	return s.jwtService.GenerateTokenPair(userID, dbUsername, roles)
}

func (s *AuthService) Refresh(ctx context.Context, refreshToken string) (TokenPair, error) {
	claims, err := s.jwtService.ParseRefreshToken(strings.TrimSpace(refreshToken))
	if err != nil {
		return TokenPair{}, err
	}
	var (
		username string
		status   int16
	)
	row := s.db.QueryRow(ctx, `
SELECT username, status
FROM users
WHERE id = $1
  AND deleted_at IS NULL
`, claims.UserID)
	if err = row.Scan(&username, &status); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return TokenPair{}, ErrInvalidCredentials
		}
		return TokenPair{}, err
	}
	if status != 1 {
		return TokenPair{}, ErrUserDisabled
	}
	roles, err := s.listRoles(ctx, claims.UserID)
	if err != nil {
		return TokenPair{}, err
	}
	return s.jwtService.GenerateTokenPair(claims.UserID, username, roles)
}

func (s *AuthService) Register(ctx context.Context, input RegisterInput) (RegisterResult, error) {
	username := strings.TrimSpace(input.Username)
	email := strings.TrimSpace(input.Email)
	password := strings.TrimSpace(input.Password)
	if username == "" || email == "" || password == "" {
		return RegisterResult{}, ErrInvalidArgument
	}
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return RegisterResult{}, err
	}
	result := RegisterResult{}
	row := s.db.QueryRow(ctx, `
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
	1,
	1,
	1,
	1
)
RETURNING id, username, email
`, username, email, strings.TrimSpace(input.UsedBy), strings.TrimSpace(input.EmployeeNo), strings.TrimSpace(input.Phone), string(passwordHash))
	if err = row.Scan(&result.UserID, &result.Username, &result.Email); err != nil {
		if isUniqueViolation(err) {
			return RegisterResult{}, ErrUserConflict
		}
		return RegisterResult{}, err
	}
	return result, nil
}

func (s *AuthService) VerifyAccessToken(accessToken string) (AuthClaims, error) {
	return s.jwtService.ParseAccessToken(strings.TrimSpace(accessToken))
}

func (s *AuthService) listRoles(ctx context.Context, userID int64) ([]string, error) {
	rows, err := s.db.Query(ctx, `
SELECT r.code
FROM user_roles ur
JOIN roles r ON r.id = ur.role_id
WHERE ur.user_id = $1
  AND ur.deleted_at IS NULL
  AND r.deleted_at IS NULL
ORDER BY r.code
`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	roles := make([]string, 0)
	for rows.Next() {
		var role string
		if scanErr := rows.Scan(&role); scanErr != nil {
			return nil, scanErr
		}
		roles = append(roles, role)
	}
	if rowsErr := rows.Err(); rowsErr != nil {
		return nil, rowsErr
	}
	return roles, nil
}
