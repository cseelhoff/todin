package game

Services :: struct {}

// Java uses ServiceLoader (reflection/SPI) to load any provider of T; no-op in headless port.
services_try_load_any :: proc(type_id: typeid) -> rawptr {
	return nil
}

