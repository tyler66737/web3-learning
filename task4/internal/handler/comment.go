package handler

import (
	"blog/api"
	"blog/internal/models"
	"errors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"log"
	"net/http"
	"strconv"
)

func NewCommentHandler(db *gorm.DB) *CommentHandler {
	return &CommentHandler{db: db}
}

type CommentHandler struct {
	db *gorm.DB
}

func (h *CommentHandler) Create(ctx *gin.Context) {
	var form api.CommentCreateForm
	if err := ctx.ShouldBindJSON(&form); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	var post models.Post
	if err := h.db.Where("id = ?", form.PostID).First(&post).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	userID := ctx.GetUint("user_id")
	record := models.Comment{
		UserID:  userID,
		PostID:  form.PostID,
		Content: form.Content,
	}
	if err := h.db.Create(&record).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"id": record.ID})
	return
}

func (h *CommentHandler) GetPOSTComments(ctx *gin.Context) {
	postId, _ := strconv.Atoi(ctx.Query("post_id"))
	if postId == 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}
	records := make([]models.Comment, 0)
	if err := h.db.Where("post_id = ?", postId).Find(&records).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	comments := make([]api.CommentListItem, 0)
	for _, record := range records {
		// could be optimized here
		user := models.User{}
		if err := h.db.Where("id = ?", record.UserID).First(&user); err != nil {
			log.Printf("ERROR: unble to load user: %v", err)
		}

		item := api.CommentListItem{
			ID:        record.ID,
			Content:   record.Content,
			CreatedAt: record.CreatedAt.Unix(),
			User: api.BaseUser{
				ID:       record.UserID,
				Username: user.Username,
			},
		}
		comments = append(comments, item)
	}
	ctx.JSON(http.StatusOK, comments)
	return

}

func (h *CommentHandler) GetByID(ctx *gin.Context) {
	commentID, _ := strconv.Atoi(ctx.Query("id"))
	if commentID == 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid comment ID"})
		return
	}
	var comment models.Comment
	if err := h.db.First(&comment, commentID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Comment not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	var user models.User
	if err := h.db.Where("id = ?", comment.UserID).First(&user).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	response := api.CommentDetailItem{
		ID:        comment.ID,
		Content:   comment.Content,
		CreatedAt: comment.CreatedAt.Unix(),
		User: api.BaseUser{
			ID:       user.ID,
			Username: user.Username,
		},
	}
	ctx.JSON(http.StatusOK, response)
}
