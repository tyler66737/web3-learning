package handler

import (
	"blog/api"
	"blog/internal/models"
	"errors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"net/http"
	"strconv"
)

type PostHandler struct {
	db *gorm.DB
}

func NewPostHandler(db *gorm.DB) *PostHandler {
	return &PostHandler{db: db}
}

func (p *PostHandler) Create(ctx *gin.Context) {
	var form api.PostCreateRequest
	if err := ctx.ShouldBindJSON(&form); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userID := ctx.GetUint("user_id")
	record := models.Post{
		UserID:  userID,
		Title:   form.Title,
		Content: form.Content,
	}
	if err := p.db.Create(&record).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"id": record.ID})
	return
}

func (p *PostHandler) GetByID(ctx *gin.Context) {
	postID, _ := strconv.Atoi(ctx.Query("id"))
	if postID == 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid post ID"})
		return
	}
	var record models.Post
	if err := p.db.First(&record, postID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	response := api.PostDetailItem{
		ID:        record.ID,
		Title:     record.Title,
		Content:   record.Content,
		CreatedAt: record.CreatedAt.Unix(),
	}
	ctx.JSON(http.StatusOK, response)
}

func (p *PostHandler) LIST(ctx *gin.Context) {
	records := make([]models.Post, 0)
	if err := p.db.Find(&records).Error; err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	items := make([]api.PostListItem, 0)
	for _, record := range records {
		item := api.PostListItem{
			ID:        record.ID,
			Title:     record.Title,
			Content:   record.Content,
			CreatedAt: record.CreatedAt.Unix(),
		}
		items = append(items, item)
	}
	ctx.JSON(http.StatusOK, items)
}

func (p *PostHandler) Update(ctx *gin.Context) {
	var form api.PostUpdateRequest
	if err := ctx.ShouldBindJSON(&form); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	userId := ctx.GetUint("user_id")
	if result := p.db.Model(&models.Post{}).Where("id = ? and user_id=?", form.ID, userId).Updates(models.Post{
		Title:   form.Title,
		Content: form.Content,
	}); result.Error != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	} else if result.RowsAffected == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"id":      form.ID,
		"message": "update success",
	})
	return
}

func (p *PostHandler) Delete(ctx *gin.Context) {
	var form api.PostDeleteRequest
	if err := ctx.ShouldBindJSON(&form); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if result := p.db.Where("id=? and user_id=?", form.ID, ctx.GetUint("user_id")).Delete(&models.Post{}); result.Error != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
	} else if result.RowsAffected == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Post not found"})
	} else {
		ctx.JSON(http.StatusOK, gin.H{
			"id":      form.ID,
			"message": "delete success",
		})
	}
	return
}
