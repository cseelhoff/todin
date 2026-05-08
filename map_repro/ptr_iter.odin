package main
import "core:fmt"
main :: proc() {
	m := make(map[int]int, 16)
	m[1] = 10
	m[2] = 20
	pm := &m
	// pointer auto-deref: lookup
	fmt.println("pm[1]=", pm[1])
	// pointer auto-deref: insert
	pm[3] = 30
	fmt.println("len=", len(m), len(pm^))
	// iteration
	for k, v in pm {
		fmt.println("iter", k, v)
	}
}
