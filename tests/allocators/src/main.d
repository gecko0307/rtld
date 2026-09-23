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

struct Bar
{
    int x;
    int[10] arr;
}

int main()
{
    memoryProfilerEnabled = true;
    
    int[] arr1 = New!(int[])(10);
    printFmtLn("arr1 = {0}", arr1);

    Foo foo1 = New!Foo(99);
    printFmtLn("foo1.x = {0}", foo1.x);

    Bar* bar = New!Bar(5);
    printFmtLn("bar = {0}", *bar);
    Delete(bar);
    
    Arena arena = New!Arena(1024);
    Foo foo2 = arena.create!Foo(99);
    printFmtLn("foo2.x = {0}", foo2.x);
    
    int[] arr2 = arena.create!(int[])(20);
    printFmtLn("arr = {0}", arr2);
    
    string s = arena.cat("Hello, ", "World!");
    printStrLn(s);
    
    Delete(arena);
    
    //Delete(arr);
    //Delete(foo);
    
    if (allocationCount > 0)
        printMemoryLeaks();
    
    return 0;
}
