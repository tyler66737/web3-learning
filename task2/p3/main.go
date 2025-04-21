package main

import (
	"fmt"
	"sync"
)

// 题目 ：编写一个程序，使用 go 关键字启动两个协程，一个协程打印从1到10的奇数，另一个协程打印从2到10的偶数。
func main() {
	wg := sync.WaitGroup{}
	wg.Add(2)
	go func() {
		defer wg.Done()
		for i := 0; i <= 10; i += 2 {
			fmt.Println("job 1:", i)
		}
	}()
	go func() {
		defer wg.Done()
		for i := 1; i <= 10; i += 2 {
			fmt.Println("job 2:", i)
		}
	}()
	wg.Wait()
	fmt.Println("done")
}
