package api

type RegisterForm struct {
	Email    string `json:"email" binding:"required,email"`
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type LoginForm struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type BaseUser struct {
	ID       uint   `json:"id"`
	Username string `json:"username"`
}
