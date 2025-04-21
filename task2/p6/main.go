package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	Person
	EmployeeID int
}

func (e *Employee) PrintInfo() {
	fmt.Printf("Employee Info:ID=%d,Name=%s,Age=%d", e.EmployeeID, e.Name, e.Age)
}

func main() {
	e := Employee{
		Person: Person{
			Name: "John",
			Age:  30,
		},
		EmployeeID: 123,
	}
	e.PrintInfo()
}
