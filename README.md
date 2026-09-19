# RTLD

RTLD aims to be a minimal runtime library for D, alternative to Phobos/druntime. It is not meant for generic application development, but rather for special use cases:

- Projects that need "Better BetterC". Raw BetterC mode is too restrictive. RTLD is fully `@nogc`, but supports classes, allowing to write at C++ level of abstraction
- Performance-critical applications that need really fast, C-level stuff without unnecessary abstractions
- Programming embedded devices, ARM boards and low-end computers
- System development.

RTLD supports Windows and POSIX systems and currently compiles on x86_64 and AArch64. Some parts of it are also platform-agnostic and can be used on bare metal.
