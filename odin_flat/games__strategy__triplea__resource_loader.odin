package game

// Java owners covered by this file:
//   - games.strategy.triplea.ResourceLoader

Resource_Loader :: struct {
	loader:      ^Url_Class_Loader,
	asset_paths: [dynamic]string,
}

resource_loader_new :: proc(asset_paths: [dynamic]string) -> ^Resource_Loader {
	self := new(Resource_Loader)
	self.asset_paths = asset_paths
	// Java builds a URLClassLoader from PathUtils::toUrl over assetPaths;
	// the JDK shim has no real classloading semantics, so we just allocate
	// an opaque marker. See java__net__url_class_loader.odin.
	self.loader = new(Url_Class_Loader)
	return self
}

resource_loader_find_resource :: proc(self: ^Resource_Loader, search_path_string: string) -> ^Url {
	// Java: loader.resources(searchPathString).findFirst()
	// The Url_Class_Loader shim has no real classloading, so no resource
	// is ever found; mirror the empty Optional<URL> as nil.
	_ = self
	_ = search_path_string
	return nil
}

// Java: public @Nullable URL getResource(final String inputPathString)
//   return findResource(inputPathString).orElse(null);
resource_loader_get_resource :: proc(self: ^Resource_Loader, input_path_string: string) -> ^Url {
	return resource_loader_find_resource(self, input_path_string)
}

// Synthetic lambda for the two-arg `getResource(s1, s2)` overload's
// `.or(() -> findResource(inputPathString2))`: a Supplier<Optional<URL>>
// that defers the second findResource call. With the shim's empty
// classloader this always yields nil, mirroring an empty Optional.
resource_loader_lambda_get_resource_1 :: proc(self: ^Resource_Loader, input_path_string2: string) -> ^Url {
	return resource_loader_find_resource(self, input_path_string2)
}

// Synthetic lambda for `URL[]::new` used in the constructor's
// `searchUrls.toArray(URL[]::new)` call: an IntFunction<URL[]> that
// allocates a fresh URL array of the requested length.
resource_loader_lambda_new_0 :: proc(n: i32) -> []^Url {
	return make([]^Url, n)
}

resource_loader_lambda_optional_resource_2 :: proc(url: ^Url) -> ^Uri {
	return url_to_uri(url)
}

// Synthetic lambda for `requiredResource`'s
// `orElseThrow(() -> new FileNotFoundException(pathString))`: a
// Supplier<FileNotFoundException> that builds the exception carrying
// the missing path as its message.
resource_loader_lambda_required_resource_3 :: proc(path_string: string) -> ^File_Not_Found_Exception {
	return file_not_found_exception_new(path_string)
}

// Java: public Properties loadPropertyFile(final String fileName)
//   final Properties properties = new OrderedProperties();
//   final URL url = getResource(fileName);
//   if (url != null) {
//     final Optional<InputStream> optionalInputStream = UrlStreams.openStream(url);
//     if (optionalInputStream.isPresent()) {
//       try (InputStream inputStream = optionalInputStream.get()) {
//         properties.load(inputStream);
//       } catch (final IOException e) { log.error("Error reading " + fileName, e); }
//     }
//   }
//   return properties;
resource_loader_load_property_file :: proc(self: ^Resource_Loader, file_name: string) -> ^Properties {
	properties := ordered_properties_new()
	url := resource_loader_get_resource(self, file_name)
	if url != nil {
		input_stream := url_streams_open_stream(url)
		if input_stream != nil {
			properties_load(&properties.parent, input_stream)
			input_stream_close(input_stream)
		}
	}
	return &properties.parent
}
