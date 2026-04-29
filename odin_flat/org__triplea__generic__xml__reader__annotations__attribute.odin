package game

// Port of org.triplea.generic.xml.reader.annotations.Attribute.
// Java annotation marking a field as an XML attribute. In Odin it
// is represented as a plain struct describing the annotation's
// parameters.

Attribute :: struct {
	names:           []string,
	default_value:   string,
	default_int:     int,
	default_double:  f64,
	default_boolean: bool,
}
