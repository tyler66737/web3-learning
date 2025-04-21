package task1

import (
	"sort"
)

// p56
func merge(intervals [][]int) [][]int {
	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})
	results := make([][]int, 0)
	for _, interval := range intervals {
		if len(results) > 0 {
			last := results[len(results)-1]
			if interval[0] <= last[1] {
				// if overlap, merge
				if interval[1] > last[1] {
					results[len(results)-1] = []int{last[0], interval[1]}
				}
			} else {
				results = append(results, interval)
			}
		} else {
			results = append(results, interval)
		}
	}
	return results
}
