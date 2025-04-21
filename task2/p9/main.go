package main

import (
	"fmt"
	"sync"
)

type Counter struct {
	lock  sync.Mutex
	count int
}

func (c *Counter) Increment() {
	c.lock.Lock()
	defer c.lock.Unlock()
	c.count++
}

func (c *Counter) Value() int {
	c.lock.Lock()
	defer c.lock.Unlock()
	return c.count
}

// 题目 ：编写一个程序，使用 sync.Mutex 来保护一个共享的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
// 考察点 ： sync.Mutex 的使用、并发数据安全。
func main() {
	counter := Counter{}
	wg := sync.WaitGroup{}
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < 1000; j++ {
				counter.Increment()
			}
		}()
	}
	wg.Wait()
	fmt.Println(counter.Value())
}
