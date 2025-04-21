package task1

func p69(x int) int {
	left, right := 0, x
	for left < right {
		mid := (left + right + 1) / 2
		square := mid * mid
		if square == x {
			return mid
		} else if square < x {
			left = mid
		} else {
			right = mid - 1
		}
	}
	return left
}
