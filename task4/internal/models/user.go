package models

type User struct {
	ID       uint   `gorm:"column:id;type:int;primaryKey;autoIncrement"`
	Username string `gorm:"column:username;type:varchar(64);index;not null"`
	Password string `gorm:"column:password;type:varchar(128);not null"`
	Email    string `gorm:"column:email;type:varchar(64);index;not null"`
}

func (u *User) TableName() string {
	return "users"
}
