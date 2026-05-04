package game

Product_Version_Reader :: struct {
}

// Static field: ProductVersionReader.currentVersion
product_version_reader_current_version: ^Version

// Java: public static Version getCurrentVersion() {
//     if (currentVersion == null) {
//         var resourcePropertyReader =
//             new ResourcePropertyReader("META-INF/triplea/product.properties");
//         currentVersion = new Version(resourcePropertyReader.readProperty("version"));
//     }
//     return currentVersion;
// }
product_version_reader_get_current_version :: proc() -> ^Version {
	if product_version_reader_current_version == nil {
		resource_property_reader := resource_property_reader_new("META-INF/triplea/product.properties")
		version_string := abstract_property_reader_read_property(
			&resource_property_reader.abstract_property_reader,
			"version",
		)
		product_version_reader_current_version = version_new(version_string)
	}
	return product_version_reader_current_version
}

// Java owners covered by this file:
//   - org.triplea.config.product.ProductVersionReader

