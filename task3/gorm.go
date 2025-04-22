package task3

import (
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Name  string  `gorm:"column:name"`
	Posts []*Post `gorm:"foreignKey:user_id"`
}

type Post struct {
	gorm.Model
	UserID        int        `gorm:"column:user_id;type:int;not null"`
	Title         string     `gorm:"column:title;type:varchar(64);not null;"`
	Body          string     `gorm:"column:body;type:text;not null"`
	CommentCount  int        `gorm:"column:comment_count;type:int;not null"`
	CommentStatus string     `gorm:"column:comment_status;type:varchar(64);not null"`
	Comments      []*Comment `gorm:"foreignKey:post_id"`
}

type Comment struct {
	gorm.Model
	UserID  int    `gorm:"column:user_id;type:int;not null"`
	PostID  int    `gorm:"column:post_id;type:int;not null"`
	Content string `gorm:"column:content;type:text;not null"`
}

func (p *Comment) AfterCreate(tx *gorm.DB) (err error) {
	return tx.Model(Post{}).Where("id = ?", p.PostID).Update("comment_count", gorm.Expr("comment_count + ?", 1)).Error
}

func (p *Comment) AfterDelete(tx *gorm.DB) (err error) {
	err = tx.Model(Post{}).Where("id = ?", p.PostID).Update("comment_count", gorm.Expr("comment_count - ?", 1)).Error
	if err != nil {
		return err
	}
	return tx.Where("post_id = ? and comment_count = 0", p.PostID).Update("comment_status=", "无评论").Error
}

func Migrate(db *gorm.DB) error {
	return db.Migrator().AutoMigrate(&User{}, &Post{}, &Comment{})
}

func UserArticleWithCommentsV1(db *gorm.DB, userID int) ([]*Post, error) {
	// 获取用户文章,以及对应的评论列表
	// 这里没有使用外键...
	var posts []*Post
	if err := db.Where("user_id = ?", userID).Find(&posts).Error; err != nil {
		return nil, err
	}
	for _, post := range posts {
		postComments := make([]*Comment, 0)
		if err := db.Where("post_id=?", post.ID).Find(&postComments).Error; err != nil {
			return nil, err
		}
		post.Comments = postComments
	}
	return posts, nil
}

func UserArticleWithCommentsV2(db *gorm.DB, userID int) ([]*Post, error) {
	var posts []*Post
	if err := db.Preload("comments").Where("user_id = ?", userID).Find(&posts).Error; err != nil {
		return nil, err
	}
	return posts, nil
}

func HottestArticle(db *gorm.DB) (*Post, error) {
	// 获取最热门文章
	var post Post
	if err := db.Order("comment_count desc").Limit(1).First(&post).Error; err != nil {
		return nil, err
	}
	return &post, nil
}
