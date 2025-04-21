package task1

type MyCalendar struct {
	books [][]int
}

func Constructor() MyCalendar {
	return MyCalendar{}
}

func (c *MyCalendar) Book(startTime int, endTime int) bool {
	for _, book := range c.books {
		if startTime >= book[1] || endTime <= book[0] {
			continue
		} else {
			return false
		}
	}
	c.books = append(c.books, []int{startTime, endTime})
	return true
}
