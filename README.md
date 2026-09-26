# RTLD

RTLD aims to be a minimal runtime library for D, alternative to Phobos/druntime. It is not meant for generic application development, but rather for special use cases:

- Projects that need "Better BetterC". Raw BetterC mode is too restrictive. RTLD is fully independent from druntime, but supports classes, allowing to write at C++ level of abstraction
- Performance-critical applications that can't rely on GC
- Applications that need SDL-like functionality without SDL itself
- Programming embedded devices, ARM boards and low-end computers
- System development.

RTLD supports Windows and POSIX systems and currently targets x86_64 and AArch64. Some parts of it are also platform-agnostic and can be used on bare metal.

RTLD is designed in a very similar way to [dlib](https://github.com/gecko0307/dlib) and will be a backend for the future dlib 2.0.

## Features

- `rtld.core` - cross-platform core API, including standard I/O, file I/O, memory allocator, dynamic library loader, threads, atomics, type traits, etc.
- `rtld.container` - generic data containers (WIP), array sorting
- `rtld.data` - data formats (JSON, Varint)
- `rtld.gui` - cross-platform window management
- `rtld.gl` - OpenGL ES 2/3
- `rtld.hash` - fast non-cryptographic hash functions: xxHash64, xxHash32
- `rtld.libc` - libc binding (WIP)
- `rtld.math` - elementary math functions. Provides bare metal fallbacks with performance and accuracy comparable to `std.math`
- `rtld.memory` - allocator interface and its implementations; arena allocator
- `rtld.random` - platform-independent non-cryptographic RNG based on [Permuted Congruential Generator](http://www.pcg-random.org/index.html)
- `rtld.sys.windows` - WinAPI binding (WIP)
- `rtld.sys.posix` - POSIX binding (WIP)
- `rtld.sys.linux` - Linux kernel API and subsystems binding (WIP)
- `rtld.text` - text encodings (UTF-8, UTF-16), GC-free `String` type, string formatting, lexer
- `rtld.time` - cross-platform date-time functions.

## Usage

By default RTLD can be used with Phobos as a normal source package:

```json
"dependencies": {
    "rtld": "~>0.4.0"
}
```

If you want to replace Phobos/druntime, use `no-druntime` configuration, add `rtld:runtime` subpackage, and set necessary compiler parameters that disable default runtime:

```json
"dependencies": {
    "rtld": "~>0.4.0",
    "rtld:runtime": "~>0.4.0"
},
"subConfigurations": {
    "rtld": "no-druntime"
},
"dflags": [
    "-defaultlib=",
    "-debuglib="
]
```

## Examples

Formatted output (to stdout and a file):

```d
struct Property
{
    string name;
    int value;
}

string name = "Test";
int code = 200;
float num = 0.5f;
Property prop = Property("Money", 100);
printFmtLn("string: {0}, int: {1}, hex: 0x{1:X}, float: {2}, prop: {3}", name, code, num, prop);

string utf8Str = "Обычная строка";
wstring utf16Str = "Широкая строка"w;

auto openResult = File.open("test.txt", FileAccessMode.Write);
if (!openResult.success)
    return 1;
File file = openResult.value;
file.printLn("Hello, World!");
file.printFmtLn("string: {0}, int: {1}, float: {2}, prop: {3}", name, code, num, prop);
file.printFmtLn("Unicode: {0} | {1}", utf8Str, utf16Str);
file.close();
```

GC-free string formatting with `String` type:

```d
String s = format(
    "Name: {0}, age: {1}, employed: {2}, weight: {3}",
    "John Doe",
    30,
    true,
    80.0f);
printLn(s);
s.free();
```

Creating objects:

```d
class MyClass
{
    int x;
    this(int x)
    {
        this.x = x;
    }
}

MyClass c = New!MyClass(10);
Delete(c);
```
