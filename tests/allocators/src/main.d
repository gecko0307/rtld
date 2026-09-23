module main;

import rtld;

class Foo
{
    int x;
    
    this(int x)
    {
        this.x = x;
    }
    
    ~this()
    {
        printLn("Foo destroyed");
    }
}

int main()
{
    int[] arr = New!(int[])(10);
    printFmtLn("arr = {0}", arr);
    auto rec = memRecord(arr.ptr);
    if (rec)
        printFmtLn("{0}: {1} byte(s) @ {2}({3})", rec.name, rec.size, rec.file, rec.line);
    Delete(arr);
    
    Foo foo = New!Foo(99);
    printFmtLn("foo.x = {0}", foo.x);
    rec = memRecord(cast(void*)foo);
    if (rec)
        printFmtLn("{0}: {1} byte(s) @ {2}({3})", rec.name, rec.size, rec.file, rec.line);
    Delete(foo);
    
    return 0;
}
