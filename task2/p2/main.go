package main

import "fmt"

func double(numsPtr *[]int) {
	nums := *numsPtr
	for i := 0; i < len(nums); i++ {
		nums[i] = nums[i] * 2
	}
}

// implement a func,receive a pointer to a slice of ints
// modify the slice to double its values
func main() {
	nums := []int{1, 2, 3, 4}
	double(&nums)
	fmt.Println(nums)
}
