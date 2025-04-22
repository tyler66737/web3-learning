package task3

import (
	"github.com/jmoiron/sqlx"
)

type Employee struct {
	Id         int
	Name       string
	Department string
	Salary     int
}

// GetEmployeeByDepartment 根据部门查询员工
// p3.1
func GetEmployeeByDepartment(db *sqlx.DB, department string) ([]Employee, error) {
	employees := make([]Employee, 0)
	if err := db.Select(&employees, "select * from employees where department=?", department); err != nil {
		return nil, err
	}
	return employees, nil
}

// GetEmployeeWithHighestSalary 查询工资最高的员工
// p3.2
func GetEmployeeWithHighestSalary(db *sqlx.DB) (Employee, error) {
	var employee Employee
	if err := db.Get(&employee, "select * from employees order by salary desc limit 1"); err != nil {
		return employee, err
	}
	return employee, nil
}

type Book struct {
	Id     int
	Title  string
	Author string
	Price  int
}

func GetBooksByPrice(db *sqlx.DB, minPrice, maxPrice int) ([]Book, error) {
	books := make([]Book, 0)
	if err := db.Select(&books, "select * from books where price between ? and ?", minPrice, maxPrice); err != nil {
		return nil, err
	}
	return books, nil
}
