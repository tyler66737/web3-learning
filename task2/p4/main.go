package main

import (
	"fmt"
	"sync"
	"time"
)

//  题目 ：设计一个任务调度器，接收一组任务（可以用函数表示），并使用协程并发执行这些任务，同时统计每个任务的执行时间。
//  考察点 ：协程原理、并发任务调度。

func schedule(tasks []func()) {
	wg := sync.WaitGroup{}
	for i, task := range tasks {
		wg.Add(1)
		go func(taskId int, task func()) {
			defer wg.Done()
			start := time.Now()
			task()
			elapsed := time.Since(start)
			fmt.Printf("task %d completed,elapsed %s\n", taskId, elapsed)
		}(i, task)
	}
	wg.Wait()
}

func main() {
	tasks := []func(){
		func() {
			time.Sleep(time.Second * 0)
		},
		func() {
			time.Sleep(time.Second * 2)
		},
		func() {
			time.Sleep(time.Second * 3)
		},
		func() {
			time.Sleep(time.Second * 4)
		},
	}
	schedule(tasks)
}
