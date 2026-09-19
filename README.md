# RTLD

RTLD aims to be a minimal standard library for D, alternative to Phobos/druntime. It is not meant for generic application development, but rather for special use cases:

- Projects that need "Better BetterC". Raw BetterC mode is too restrictive. RTLD is fully `@nogc`, but supports classes, allowing to write at C++ level of abstraction
- Performance-critical applications that need really fast, C-level stuff without unnecessary abstractions
- Programming embedded devices, ARM boards and low-end computers
- System development.
