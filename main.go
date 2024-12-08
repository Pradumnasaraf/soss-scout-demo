package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/kubecon", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "It's KubeCon time!",
		})
	})

	router.Run(":8080")
}
