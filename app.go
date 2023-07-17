package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"
)

// use godot package to load/read the .env file and
// return the value of the key
func goDotEnvVariable(key string) string {
    // load .env file
    err := godotenv.Load("./.env")

    if err != nil { log.Fatalf("Error loading .env file") }

    return os.Getenv(key)
}

func homePage(writter http.ResponseWriter, request *http.Request){
    fmt.Fprintf(writter, "Welcome to the HomePage!")
    fmt.Println("Endpoint Hit: homePage")
}

func handleRequests() {
    serverPort := ":" + goDotEnvVariable("SERVER_PORT")

    fmt.Printf("Server Listening at Port %s\n", serverPort)

    http.HandleFunc("/", homePage)
    log.Fatal(http.ListenAndServe(serverPort, nil))
}

func main() {
    fmt.Println("Main function called")
    handleRequests()
}