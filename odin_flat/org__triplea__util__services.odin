package game

import "core:fmt"

Services :: struct {}

// Java uses ServiceLoader (reflection/SPI) to load any provider of T; no-op in headless port.
services_try_load_any :: proc(type_id: typeid) -> rawptr {
	return nil
}

// Java: () -> new ServiceNotAvailableException(type) — Supplier<X> passed to Optional.orElseThrow
// inside Services.loadAny. Captures the requested service type.
services_lambda_load_any_0 :: proc(type_id: typeid) -> ^Service_Not_Available_Exception {
	return service_not_available_exception_new(fmt.tprintf("%v", type_id))
}

