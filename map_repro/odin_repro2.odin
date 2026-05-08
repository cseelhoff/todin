package main

import "core:fmt"

insert_one :: proc(m: ^map[int]int, k: int) {
	// m := m // shadow to make mutable — pattern used throughout the AI port
	m[k] = 100
}

main :: proc() {
	m := make(map[int]int, 16) // pre-allocate so no realloc
	insert_one(&m, 1)
	insert_one(&m, 1) // same key, should overwrite
	insert_one(&m, 2)
	fmt.println("len=", len(m), "m[1]=", m[1], "m[2]=", m[2])
}
