package task3

import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	"log"
	"testing"
)

func getDB() *sql.DB {
	username := "root"
	password := "root"
	database := "demo"
	dsn := fmt.Sprintf("%s:%s@tcp(127.0.0.1:3306)/%s?charset=utf8mb4&parseTime=True&loc=Local", username, password, database)
	var err error
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal(err)
	}
	return db
}

func TestSqlCRUD(t *testing.T) {
	db := getDB()
	err := crud(db)
	if err != nil {
		t.Error(err)
	}
}

func TestTransfer(t *testing.T) {
	db := getDB()
	// prepare data
	if _, err := db.Exec("create table accounts(id int primary key auto_increment,balance int)"); err != nil {
		t.Error(err)
		return
	}
	if _, err := db.Exec("create table transactions(id int primary key auto_increment,from_account_id int,to_account_id int,amount int)"); err != nil {
		t.Error(err)
		return
	}
	if _, err := db.Exec("truncate table accounts"); err != nil {
		t.Error(err)
		return
	}
	if _, err := db.Exec("insert into accounts(id,balance) values (1,100),(2,50)"); err != nil {
		t.Error(err)
		return
	}
	t.Run("rollback", func(t *testing.T) {
		err := Transfer(db, 1, 2, 200)
		if err == nil {
			t.Logf("expect to get err but get nil")
		}
		t.Logf("transfer returns : %v", err)
	})
	t.Run("success", func(t *testing.T) {
		err := Transfer(db, 1, 2, 50)
		if err != nil {
			t.Errorf("unexpected error : %v", err)
		}
	})
}
