package api

type CommentCreateForm struct {
	PostID  uint   `json:"post_id" binding:"required"`
	Content string `json:"content" binding:"required"`
}

type CommentListItem struct {
	ID        uint     `json:"id"`
	PostID    uint     `json:"post_id"`
	Content   string   `json:"content"`
	CreatedAt int64    `json:"created_at"`
	User      BaseUser `json:"user"`
}

type CommentDetailItem struct {
	ID        uint     `json:"id"`
	PostID    uint     `json:"post_id"`
	Content   string   `json:"content"`
	CreatedAt int64    `json:"created_at"`
	User      BaseUser `json:"user"`
}
