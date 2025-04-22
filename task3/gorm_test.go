package task3

import (
	"fmt"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"testing"
)

func getGorm() *gorm.DB {
	username := "root"
	password := "root"
	database := "demo"
	dsn := fmt.Sprintf("%s:%s@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", username, password, database)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	return db.Debug()
}

func TestMigrate(t *testing.T) {
	err := Migrate(getGorm())
	if err != nil {
		t.Error(err)
	}
}
func TestSetup(t *testing.T) {
	db := getGorm()
	db.Create(&User{Name: "john"})
	db.Create(&Post{
		UserID:        1,
		Title:         "title",
		Body:          "body",
		CommentCount:  0,
		CommentStatus: "",
		Comments:      nil,
	})
	db.Create([]Comment{
		{Content: "comment1", UserID: 1, PostID: 1},
		{Content: "comment2", UserID: 1, PostID: 1},
	})
}

func TestUserArticleWithCommentsV1(t *testing.T) {
	db := getGorm()
	_, err := UserArticleWithCommentsV1(db, 1)
	if err != nil {
		t.Error(err)
	}
}

func TestUserArticleWithCommentsV2(t *testing.T) {
	db := getGorm()
	_, err := UserArticleWithCommentsV1(db, 1)
	if err != nil {
		t.Error(err)
	}
}

func TestHottestArticle(t *testing.T) {
	db := getGorm()
	_, err := HottestArticle(db)
	if err != nil {
		t.Error(err)
	}
}
