package game

// JDK shim: opaque marker for java.net.URLClassLoader. Map ResourceLoader
// holds one to load resources from map zip files. The AI snapshot harness
// uses pre-loaded GameData and never re-resolves classpath resources, so
// no real classloading semantics are required.
Url_Class_Loader :: struct {}
