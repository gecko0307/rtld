# RTLD

RTLD aims to be a minimal runtime library for D, alternative to Phobos/druntime. It is not meant for generic application development, but rather for special use cases:

- Projects that need "Better BetterC". Raw BetterC mode is too restrictive. RTLD is fully `@nogc`, but supports classes, allowing to write at C++ level of abstraction
- Performance-critical applications that need really fast runtime functionality
- Programming embedded devices, ARM boards and low-end computers
- System development.

RTLD supports Windows and POSIX systems and currently compiles on x86_64 and AArch64. Some parts of it are also platform-agnostic and can be used on bare metal.

## Features

- `rtld.core` - cross-platform core API, including I/O, memory allocations, dynamic library loader, threads, etc.
- `rtld.gl`- OpenGL ES 2/3
- `rtld.libc` - libc binding (WIP)
- `rtld.math` - basic math functions
- `rtld.random` - platform-independent non-cryptographic RNG based on Permuted Congruential Generator
- `rtld.sys.windows` - WinAPI binding (WIP)
- `rtld.sys.posix` - POSIX binding (WIP)
- `rtld.sys.linux` - Linux kernel API and subsystems binding (WIP)
- `rtld.test` - text encodings implementation
- `rtld.time` - cross-platform date-time functions.

## Usage

By default RTLD can be used with Phobos as a normal source package:

```json
"dependencies": {
    "rtld": "~>0.1.0"
}
```

If you want to replace Phobos/druntime, use `no-druntime` configuration, add `rtld:runtime`, and set necessary compiler parameters. We recommend LDC for this.

```json
"dependencies": {
    "rtld": "~>0.1.0",
    "rtld:runtime": "~>0.1.0"
},
"subConfigurations": {
    "rtld": "no-druntime"
},
"dflags-ldc": [
    "--vgc",
    "-defaultlib=",
    "-debuglib="
]
```
