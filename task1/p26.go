package task1

// delete duplicate items in sorted array
func p26(nums []int) int {
	i := 0
	for j := 1; j < len(nums); j += 1 {
		if nums[i] != nums[j] {
			nums[i+1] = nums[j]
			i += 1
		}
	}
	return i + 1
}
