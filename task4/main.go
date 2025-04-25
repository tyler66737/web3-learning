package main

import (
	"blog/internal/config"
	"blog/internal/handler"
	"blog/internal/middleware"
	"blog/internal/models"
	"context"
	"fmt"
	"github.com/gin-gonic/gin"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"log"
	"net/http"
	"os"
	"os/signal"
)

func main() {
	cfg, err := config.LoadConfig("cfg.json")
	if err != nil {
		log.Fatalf("load config fail: %v", err)
		return
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local", cfg.DB.Username, cfg.DB.Password, cfg.DB.Host, cfg.DB.Port, cfg.DB.Database)
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("fail to connect database: %v", err)
		return
	}

	if err := db.Migrator().AutoMigrate(&models.User{}, &models.Comment{}, &models.Post{}); err != nil {
		log.Fatalf("fail to migrate database: %v", err)
		return
	}

	g := gin.Default()
	setupRouter(db, g, cfg)

	server := http.Server{
		Addr:    ":9000",
		Handler: g,
	}
	ch := make(chan os.Signal)
	go func() {
		if err := server.ListenAndServe(); err != nil {
			log.Printf("service exit with error: %v", err)
		}
		close(ch)
	}()
	signal.Notify(ch, os.Interrupt, os.Kill)
	<-ch
	_ = server.Shutdown(context.Background())

}

func setupRouter(db *gorm.DB, r gin.IRouter, cfg *config.Config) {
	api := r.Group("/api")
	{
		userHandler := handler.NewUserHandler(db, cfg)
		api.POST("/register", userHandler.Register)
		api.POST("/login", userHandler.Login)
	}
	commentHandler := handler.NewCommentHandler(db)
	postHandler := handler.NewPostHandler(db)
	api.Use(middleware.JwtAuth(cfg.SecretKey))
	{
		postRouter := api.Group("/posts")
		postRouter.POST("/createPost", postHandler.Create)
		postRouter.POST("/updatePost", postHandler.Update)
		postRouter.POST("/deletePost", postHandler.Delete)
		postRouter.GET("/getPostByID", postHandler.GetByID)
		postRouter.GET("/getPosts", postHandler.LIST)
	}
	{
		commentRouter := api.Group("/comments")
		commentRouter.POST("/createComment", commentHandler.Create)
		commentRouter.GET("/getCommentByID", commentHandler.GetByID)
		commentRouter.GET("/getPostComments", commentHandler.GetPOSTComments)
	}

}
