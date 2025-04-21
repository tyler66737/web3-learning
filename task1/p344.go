package task1

// reverse string
func p344(s []byte) {
	for lo, hi := 0, len(s)-1; lo < hi; lo, hi = lo+1, hi-1 {
		s[lo], s[hi] = s[hi], s[lo]
	}
}
