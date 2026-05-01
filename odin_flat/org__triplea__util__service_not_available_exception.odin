package game

import "core:fmt"

Service_Not_Available_Exception :: struct {
	message: string,
}

service_not_available_exception_new :: proc(service_type_name: string) -> ^Service_Not_Available_Exception {
	self := new(Service_Not_Available_Exception)
	self.message = fmt.aprintf("No service available of type '%s'", service_type_name)
	return self
}

// Java owners covered by this file:
//   - org.triplea.util.ServiceNotAvailableException

