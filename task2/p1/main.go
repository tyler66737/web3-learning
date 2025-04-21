package main

import "fmt"

func f(num *int) {
	*num += 10
}

func main() {
	num := 100
	f(&num)
	fmt.Println(num)
	// output: 110
}
