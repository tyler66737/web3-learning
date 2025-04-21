package task1

// p198
func rob(nums []int) int {
	if len(nums) <= 1 {
		if len(nums) == 0 {
			return 0
		}
		return nums[0]
	}
	dp := make([]int, len(nums))
	dp[0] = nums[0]
	dp[1] = max(nums[0], nums[1])
	for i := 2; i < len(nums); i++ {
		dp[i] = max(dp[i-2]+nums[i], dp[i-1])
	}
	return dp[len(nums)-1]
}

// for older version
//func max(a,b int)int{
//	if a>b{
//		return a
//	}
//	return b
//}
