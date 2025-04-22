package task3

import (
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
	"log"
	"testing"
)

func GetSqlxDB() *sqlx.DB {
	username := "root"
	password := "root"
	database := "demo"
	dsn := fmt.Sprintf("%s:%s@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", username, password, database)
	var err error
	db, err := sqlx.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}
	return db
}

func TestGetEmployeeByDepartment(t *testing.T) {
	db := GetSqlxDB()
	employees, err := GetEmployeeByDepartment(db, "IT")
	if err != nil {
		log.Fatal(err)
	}
	for _, employee := range employees {
		fmt.Printf("Employee: %+v\n", employee)
	}
}

func TestGetEmployeeWithHighestSalary(t *testing.T) {
	db := GetSqlxDB()
	employee, err := GetEmployeeWithHighestSalary(db)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Employee: %+v\n", employee)
}
func TestGetGetBooksByPrice(t *testing.T) {
	db := GetSqlxDB()
	books, err := GetBooksByPrice(db, 10, 30)
	if err != nil {
		t.Error(err)
		return
	}
	for _, book := range books {
		t.Logf("book:%+v", book)
	}
}
