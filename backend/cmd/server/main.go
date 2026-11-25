package main

import (
	"backend/internal/routes"
	"log"
	"net/http"
)

func main() {
	log.Println("Starting server...")

	mux := http.NewServeMux()

	routes.Hello(mux)

	log.Fatal(http.ListenAndServe(":8080", mux))
}
