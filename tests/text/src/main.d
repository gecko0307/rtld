module main;

import rtld;

int main()
{
    printf("Testing unicode subsystem round-trip...\n");

    string source8 = "Привет, мир!";
    printf("Source UTF-8: %.*s\n", cast(int)source8.length, source8.ptr);

    ubyte[1024] utf16Buffer = void;
    const(wchar)* winPathz = toUTF16z(source8, utf16Buffer);
    if (winPathz is null)
    {
        printf("Test FAILED: toUTF16z returned null\n");
        return 1;
    }

    size_t utf16Length = 0;
    while (winPathz[utf16Length] != '\0')
    {
        utf16Length++;
    }
    const(wchar)[] intermediate16 = winPathz[0 .. utf16Length];

    ubyte[1024] utf8Buffer = void;
    const(char)* finalUtf8z = toUTF8z(intermediate16, utf8Buffer[]);
    if (finalUtf8z is null)
    {
        printf("Test FAILED: toUTF8z returned null\n");
        return 1;
    }

    printf("Result UTF-8: %s\n", finalUtf8z);

    ubyte[1024] expectedBuffer = void;
    expectedBuffer[0 .. source8.length] = cast(ubyte[])source8[];
    expectedBuffer[source8.length] = '\0';
    
    if (strcmp(finalUtf8z, cast(const(char)*)expectedBuffer.ptr) == 0)
    {
        printf("SUCCESS: Unicode subsystem round-trip completed flawlessly!\n");
    }
    else
    {
        printf("Test FAILED: Result string mismatch!\n");
        return 1;
    }

    return 0;
}
