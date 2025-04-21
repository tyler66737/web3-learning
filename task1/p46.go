package task1

import "fmt"

func p46(nums []int) [][]int {
	results := make([][]int, 0)
	fillCombs(&results, 0, nums)
	return results
}

func fillCombs(results *[][]int, p int, nums []int) {
	if p == len(nums)-1 {
		result := make([]int, len(nums))
		copy(result, nums)
		*results = append(*results, result)
		return
	}
	fillCombs(results, p+1, nums)
	for i := p + 1; i < len(nums); i++ {
		nums[p], nums[i] = nums[i], nums[p]
		fillCombs(results, p+1, nums)
		nums[p], nums[i] = nums[i], nums[p]
	}
}

func main() {
	nums := []int{1, 2, 3}
	result := p46(nums)
	fmt.Println(result)
	// output: [[1 2 3] [1 3 2] [2 1 3] [2 3 1] [3 2 1] [3 1 2]]

}
