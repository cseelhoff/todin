package game

import "core:strings"

// Java owners covered by this file:
//   - org.triplea.generic.xml.reader.exceptions.JavaDataModelException

Java_Data_Model_Exception :: struct {
	using exception: Exception,
}

// Java: public JavaDataModelException(final String message)
//   super("Error in Java XML model code, " + message);
java_data_model_exception_new :: proc(message: string) -> ^Java_Data_Model_Exception {
	self := new(Java_Data_Model_Exception)
	self.exception.message = strings.concatenate({"Error in Java XML model code, ", message})
	return self
}

// Java: public JavaDataModelException(final String message, final Throwable cause)
//   super("Error in Java XML model code, " + message, cause);
java_data_model_exception_new_with_cause :: proc(message: string, cause: ^Throwable) -> ^Java_Data_Model_Exception {
	self := new(Java_Data_Model_Exception)
	self.exception.message = strings.concatenate({"Error in Java XML model code, ", message})
	if cause != nil {
		wrapped := new(Exception)
		wrapped.message = cause.message
		self.exception.cause = wrapped
	}
	return self
}

// Java: public JavaDataModelException(final Field field, final String message)
//   super("Error in field: " + field + ", " + message);
java_data_model_exception_new_for_field :: proc(field: ^Field, message: string) -> ^Java_Data_Model_Exception {
	self := new(Java_Data_Model_Exception)
	self.exception.message = strings.concatenate({"Error in field: ", field_to_string(field), ", ", message})
	return self
}

// Java: public JavaDataModelException(final Field field, final String message, final Throwable e)
//   super("Error in Java XML model code, field: " + field + ", " + message, e);
java_data_model_exception_new_for_field_with_cause :: proc(field: ^Field, message: string, cause: ^Throwable) -> ^Java_Data_Model_Exception {
	self := new(Java_Data_Model_Exception)
	self.exception.message = strings.concatenate({"Error in Java XML model code, field: ", field_to_string(field), ", ", message})
	if cause != nil {
		wrapped := new(Exception)
		wrapped.message = cause.message
		self.exception.cause = wrapped
	}
	return self
}
