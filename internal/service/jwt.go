package service

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"quick/internal/config"
)

var (
	ErrTokenInvalid = errors.New("token invalid")
	ErrTokenExpired = errors.New("token expired")
)

type AuthClaims struct {
	UserID   int64
	Username string
	Roles    []string
	TokenUse string
	TokenID  string
	ExpireAt time.Time
}

type tokenClaims struct {
	Username string   `json:"username"`
	Roles    []string `json:"roles"`
	TokenUse string   `json:"token_use"`
	jwt.RegisteredClaims
}

type JWTService struct {
	issuer           string
	secret           []byte
	accessTTL        time.Duration
	refreshTTL       time.Duration
	accessTTLSeconds int64
}

func NewJWTService(cfg config.JWTConfig) (*JWTService, error) {
	secret := strings.TrimSpace(cfg.Secret)
	if secret == "" {
		return nil, errors.New("jwt secret is empty")
	}
	issuer := strings.TrimSpace(cfg.Issuer)
	if issuer == "" {
		issuer = "quick"
	}
	accessTTL := time.Duration(cfg.AccessTTLMinutes) * time.Minute
	if accessTTL <= 0 {
		accessTTL = 30 * time.Minute
	}
	refreshTTL := time.Duration(cfg.RefreshTTLHours) * time.Hour
	if refreshTTL <= 0 {
		refreshTTL = 7 * 24 * time.Hour
	}
	return &JWTService{
		issuer:           issuer,
		secret:           []byte(secret),
		accessTTL:        accessTTL,
		refreshTTL:       refreshTTL,
		accessTTLSeconds: int64(accessTTL.Seconds()),
	}, nil
}

func (s *JWTService) GenerateTokenPair(userID int64, username string, roles []string) (TokenPair, error) {
	accessToken, err := s.generateToken(userID, username, roles, "access", s.accessTTL)
	if err != nil {
		return TokenPair{}, err
	}
	refreshToken, err := s.generateToken(userID, username, roles, "refresh", s.refreshTTL)
	if err != nil {
		return TokenPair{}, err
	}
	return TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    s.accessTTLSeconds,
	}, nil
}

func (s *JWTService) ParseAccessToken(tokenString string) (AuthClaims, error) {
	return s.parseToken(tokenString, "access")
}

func (s *JWTService) ParseRefreshToken(tokenString string) (AuthClaims, error) {
	return s.parseToken(tokenString, "refresh")
}

func (s *JWTService) generateToken(userID int64, username string, roles []string, tokenUse string, ttl time.Duration) (string, error) {
	now := time.Now()
	jti, err := randomID()
	if err != nil {
		return "", err
	}
	claims := tokenClaims{
		Username: username,
		Roles:    slices.Clone(roles),
		TokenUse: tokenUse,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   strconv.FormatInt(userID, 10),
			Issuer:    s.issuer,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(ttl)),
			ID:        jti,
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secret)
}

func (s *JWTService) parseToken(tokenString string, requiredUse string) (AuthClaims, error) {
	claims := &tokenClaims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrTokenInvalid
		}
		return s.secret, nil
	})
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return AuthClaims{}, ErrTokenExpired
		}
		return AuthClaims{}, ErrTokenInvalid
	}
	if token == nil || !token.Valid {
		return AuthClaims{}, ErrTokenInvalid
	}
	if claims.TokenUse != requiredUse {
		return AuthClaims{}, ErrTokenInvalid
	}
	if claims.Issuer != s.issuer {
		return AuthClaims{}, ErrTokenInvalid
	}
	userID, convErr := strconv.ParseInt(claims.Subject, 10, 64)
	if convErr != nil {
		return AuthClaims{}, ErrTokenInvalid
	}
	if claims.ExpiresAt == nil {
		return AuthClaims{}, ErrTokenInvalid
	}
	return AuthClaims{
		UserID:   userID,
		Username: claims.Username,
		Roles:    slices.Clone(claims.Roles),
		TokenUse: claims.TokenUse,
		TokenID:  claims.ID,
		ExpireAt: claims.ExpiresAt.Time,
	}, nil
}

func randomID() (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("generate random id: %w", err)
	}
	return hex.EncodeToString(buf), nil
}
