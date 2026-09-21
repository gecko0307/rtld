module main;

import rtld;

int main()
{
    printf("File info for test.txt:\n");
    auto statResult = File.stat("test.txt");
    if (!statResult.success)
        return 1;
    FileStat* stat = &statResult.value;
    auto cTime = &stat.creationTime;
    auto mTime = &stat.modificationTime;
    size_t size = cast(size_t)stat.size;
    printf("Is directory: %d\n", stat.isDirectory);
    printf("Size: %zu byte(s)\n", size);
    printf("Creation time: %02d.%02d.%d %02d:%02d:%02d\n", cTime.day, cTime.month, cTime.year, cTime.hours, cTime.minutes, cTime.seconds);
    printf("Modification time: %02d.%02d.%d %02d:%02d:%02d\n", mTime.day, mTime.month, mTime.year, mTime.hours, mTime.minutes, mTime.seconds);
    printf("Read: %d\n", (stat.permissions & FilePermission.Read) != 0);
    printf("Write: %d\n", (stat.permissions & FilePermission.Write) != 0);
    printf("Execute: %d\n", (stat.permissions & FilePermission.Execute) != 0);
    
    if (stat.isDirectory)
        return 0;
    
    printf("Reading file test.txt...\n");
    auto openResult = File.open("test.txt");
    if (!openResult.success)
        return 1;
    File file = openResult.value;
    scope(exit)
    {
        file.close();
    }
    if (size > 0)
    {
        ubyte[] buffer = create!(ubyte[])(size);
        scope(exit)
        {
            destroy(buffer);
        }
        auto readResult = file.read(buffer);
        if (!readResult.success)
            return 1;
        size_t bytesRead = readResult.value;
        if (bytesRead > 0)
        {
            const(char)[] str = cast(char[])buffer[0..bytesRead];
            printf("File content:\n");
            printf("%.*s\n", bytesRead, str.ptr);
        }
    }
    
    return 0;
}
