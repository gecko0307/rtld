RTLD 0.6.0 - TBD
----------------
* **rtld.data**
  * New package `rtld.data` for data formats implementations. Currently it contains JSON parser (`rtld.data.json`) and Varint encoder/decoder (`rtld.data.varint`)
* **rtld.container**
  * `LinearHashMap`
* **rtld.hash**
  * New module `rtld.hash.xxhash32`
* **rtld.math**
  * `rtld.math.fallback` unittests.

RTLD 0.5.0 - 25 Sep, 2026
-------------------------
* **rtld.core**
  * New module `rtld.core.compound`
  * Improve formatted printing in `rtld.core.io`
* **rtld.gui**
  * `rtld.core.window` moved to the new package `rtld.gui`
* **rtld.text**
  * New module `rtld.text.lexer`
  * New module `rtld.text.ascii`
  * New module `rtld.text.utils`
* **rtld.math**
  * New module `rtld.math.angles`
  * New base math function `modf`.

RTLD 0.4.0 - 24 Sep, 2026
-------------------------
* **rtld.core**
  * New module `rtld.core._version`
  * New module `rtld.core.bitio`
  * New module `rtld.core.tuple`
* **rtld.memory**
  * New module `rtld.memory.arena`
* **rtld.container**
  * `rtld.container.sorting`
  * `rtld.container.hashmap`
* **rtld.text**
  * New module `rtld.text.str`
  * New module `rtld.text.format`
* **rtld.math**
  * Many `rtld.math.fallback` fixes
* **runtime**
  * Many runtime fixes.

RTLD 0.3.0 - 23 Sep, 2026
-------------------------
* **rtld.core**
  * Memory profiler in `rtld.core.memory`
  * New module `rtld.core.atomic`
* **rtld.memory**
  * New package `rtld.memory`.

RTLD 0.2.0 - 22 Sep, 2026
-------------------------
* **rtld.core**
  * New module `rtld.core.file`
  * Basic formatted output support in `rtld.core.io`
* **rtld.container**
  * New package `rtld.container`
* **rtld.text**
  * New module `rtld.text.utf16`
* **rtld.libc**
  * More libc functions
* **rtld.sys**
  * More POSIX functions.

RTLD 0.1.0 - 20 Sep, 2026
-------------------------
Project started.
