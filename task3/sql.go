package task3

import (
	"database/sql"
	"errors"
	"fmt"
	"log"
)

func crud(db *sql.DB) error {
	_, err := db.Exec("create table if not exists students(id int primary key auto_increment,name varchar(20),age int,grade varchar(3))")
	if err != nil {
		return fmt.Errorf("create table fail: %w", err)
	}
	// truncate table
	_, err = db.Exec("truncate table students")
	if err != nil {
		return fmt.Errorf("clear table fail: %w", err)
	}
	// insert
	result, err := db.Exec("insert into students(name,age,grade) values (?,?,?)", "张三", 20, "三年级")
	if err != nil {
		return fmt.Errorf("insert fail: %w ", err)
	}
	insertedId, _ := result.LastInsertId()
	log.Printf("create student success,lastInsertedId=%d", insertedId)
	// query students age > 18
	rows, err := db.Query("select id,name,age,grade from students where age > ?", 18)
	if err != nil {
		return fmt.Errorf("query fail: %w ", err)
	}
	for rows.Next() {
		var id int
		var name string
		var age int
		var grade string
		if err := rows.Scan(&id, &name, &age, &grade); err != nil {
			return fmt.Errorf("scan fail: %w", err)
		}
		log.Printf("query student: id=%d,name=%s,age=%d,grade=%s", id, name, age, grade)
	}

	// update
	result, err = db.Exec("update students set grade=? where name=?", "四年级", "张三")
	if err != nil {
		return fmt.Errorf("update fail: %v ", err)
	}
	rowsAffected, _ := result.RowsAffected()
	log.Printf("update success: rows affected=%d", rowsAffected)

	// delete
	result, err = db.Exec("delete from students where age< ?", 15)
	if err != nil {
		return fmt.Errorf("delete fail: %w ", err)
	}
	rowsAffected, _ = result.RowsAffected()
	log.Printf("delete students: rows affected=%d", rowsAffected)
	return nil
}

func Transfer(db *sql.DB, fromID, toId int, amount int) error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	commited := false
	defer func() {
		if !commited {
			tx.Rollback()
		}
	}()
	row := tx.QueryRow("select balance from accounts where id=?", fromID)
	var balance int
	if err := row.Scan(&balance); err != nil {
		return err
	}
	if balance < amount {
		return errors.New("insufficient balance")
	}
	if _, err := tx.Exec("update accounts set balance=balance-? where id =?", amount, fromID); err != nil {
		return err
	}
	if _, err := tx.Exec("update accounts set balance=balance+? where id=?", amount, toId); err != nil {
		return err
	}
	if _, err := tx.Exec("insert into transactions(from_account_id,to_account_id,amount) value(?,?,?)", fromID, toId, amount); err != nil {
		return err
	}
	commited = true
	return tx.Commit()
}
