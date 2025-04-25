package middleware

import (
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"net/http"
)

type userInfo struct {
	userID   uint
	username string
}

func validateToken(secret, tokenValue string) (*userInfo, bool) {
	if tokenValue == "" {
		return nil, false
	}
	if len(tokenValue) <= 7 {
		return nil, false
	}
	// Bearer ${token}
	tokenValue = tokenValue[7:]
	token, err := jwt.Parse(tokenValue, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return nil, false
	}
	if !token.Valid {
		return nil, false
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, false
	}
	userID, _ := claims["id"].(float64)
	username, _ := claims["username"].(string)
	if uint(userID) == 0 {
		return nil, false
	}
	return &userInfo{uint(userID), username}, true
}
func JwtAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.GetHeader("Authorization")
		fmt.Println("token:", token)
		if user, ok := validateToken(secret, token); ok {
			c.Set("user_id", user.userID)
			c.Set("username", user.username)
			c.Next()
		} else {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			c.Abort()
		}
	}
}
