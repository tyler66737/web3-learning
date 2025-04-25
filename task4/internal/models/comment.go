package models

import "gorm.io/gorm"

type Comment struct {
	gorm.Model
	UserID  uint   `gorm:"column:user_id;type:int;index;not null"`
	PostID  uint   `gorm:"column:post_id;type:int;index;not null"`
	Content string `gorm:"column:content;type:text;not null"`
}

func (c *Comment) TableName() string {
	return "comments"
}
