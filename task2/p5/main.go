package main

import (
	"fmt"
	"math"
)

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	width float64
}

func (r *Rectangle) Area() float64 {
	return r.width * r.width
}

func (r *Rectangle) Perimeter() float64 {
	return 4 * r.width
}

type Circle struct {
	radius float64
}

func (c *Circle) Area() float64 {
	return math.Pi * c.radius * c.radius
}

func (c *Circle) Perimeter() float64 {
	return 2 * math.Pi * c.radius
}

func main() {
	var s1, s2 Shape
	s1 = &Rectangle{width: 1}
	s2 = &Circle{radius: 1}
	fmt.Printf("rectangle: perimeter=%.2f,area=%.2f\n", s1.Perimeter(), s1.Area())
	fmt.Printf("circle: perimeter=%.2f,area=%.2f\n", s2.Perimeter(), s2.Area())
}
