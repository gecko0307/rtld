module main;

import rtld;
import rtld.libc.string;

int main()
{
    printLn("Testing unicode subsystem round-trip...");

    string source8 = "Привет, мир!";
    printFmtLn("Source UTF-8: {0}", source8);

    ubyte[1024] utf16Buffer = void;
    const(wchar)* winPathz = toUTF16z(source8, utf16Buffer);
    if (winPathz is null)
    {
        printLn("Test FAILED: toUTF16z returned null");
        return 1;
    }

    size_t utf16Length = 0;
    while (winPathz[utf16Length] != '\0')
    {
        utf16Length++;
    }
    const(wchar)[] intermediate16 = winPathz[0 .. utf16Length];

    ubyte[1024] utf8Buffer = void;
    const(char)* finalUtf8z = toUTF8z(intermediate16, utf8Buffer);
    if (finalUtf8z is null)
    {
        printLn("Test FAILED: toUTF8z returned null");
        return 1;
    }

    auto utf8Str = cast(char[])utf8Buffer[0..strlen(finalUtf8z)];
    printFmtLn("Result UTF-8: {0}", utf8Str);

    ubyte[1024] expectedBuffer = void;
    expectedBuffer[0..source8.length] = cast(ubyte[])source8[];
    expectedBuffer[source8.length] = '\0';
    
    if (strcmp(finalUtf8z, cast(const(char)*)expectedBuffer.ptr) == 0)
    {
        printLn("SUCCESS: Unicode subsystem round-trip completed flawlessly!");
    }
    else
    {
        printLn("Test FAILED: Result string mismatch!");
        return 1;
    }

    return 0;
}
