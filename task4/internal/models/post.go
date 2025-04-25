package models

import "gorm.io/gorm"

type Post struct {
	gorm.Model
	UserID  uint   `gorm:"column:user_id;type:int;index;not null"`
	Title   string `gorm:"column:title;type:varchar(64);not null"`
	Content string `gorm:"column:content;type:text;not null"`
}

func (p *Post) TableName() string {
	return "posts"
}
