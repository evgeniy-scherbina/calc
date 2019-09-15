package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"

	"github.com/evgeniy-scherbina/calc/calc_errors"
)

func sumHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)

	a, err := strconv.Atoi(vars["a"])
	if err != nil {
		w.Write([]byte(calc_errors.ErrInvalidUserData.Error()))
		return
	}

	b, err := strconv.Atoi(vars["b"])
	if err != nil {
		w.Write([]byte(calc_errors.ErrInvalidUserData.Error()))
		return
	}

	response := fmt.Sprintf("Result: %v", a+b)
	fmt.Fprint(w, response)
}

func main() {
	router := mux.NewRouter()
	router.HandleFunc("/api/v1/calc/add/{a}/{b}", sumHandler)
	http.Handle("/", router)

	fmt.Println("Server is listening...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
