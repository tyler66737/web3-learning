package task1

func p136(nums []int) int {
	var target int
	for _, num := range nums {
		target ^= num
	}
	return target
}
