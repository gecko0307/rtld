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
    int y;
}

int main()
{
    memoryProfilerEnabled = true;
    
    // Dynamic array
    version(None)
    {
        int[] arr = New!(int[])(10);
        printFmtLn("arr = {0}", arr);
        Delete(arr);
    }
    
    // Class instancing
    version(None)
    {
        Foo foo = New!Foo(99);
        printFmtLn("foo.x = {0}", foo.x);
        Delete(foo);
    }
    
    // Structure instancing
    version(None)
    {
        Bar* bar = New!Bar(5);
        printFmtLn("bar = {0}", *bar);
        Delete(bar);
    }
    
    // Arena
    version(None)
    {
        Arena arena = New!Arena(1024);
        
        Foo foo = arena.create!Foo(99);
        printFmtLn("Arena.foo.x = {0}", foo.x);

        int[] arr = arena.create!(int[])(20);
        printFmtLn("Arena.arr = {0}", arr);
        
        string s = arena.cat("Hello, ", "World!");
        printFmtLn("Arena.s = {0}", s);
        
        Delete(arena);
    }
    
    // Literals
    version(None)
    {
        Bar[] arr1 = [Bar(1, 2), Bar(5, 6), Bar(0, 0)];
        printLn(arr1);
        
        float[] arr2 = [0.1f, 0.0f, 0.0f];
        printLn(arr2);
        
        int[] arr3 = [100, 50, 85, 10, 5, 99, 0];
        insertionSort!((a, b) => a < b)(arr3);
        printLn(arr3);
    }
    
    // new for arrays
    {
        float[] arr = new float[10];
        printLn(arr);
        Delete(arr);
    }
    
    // new for classes
    {
        // TODO
    }
    
    // Should print leaked literals from object.d
    if (allocationCount > 0)
        printMemoryLeaks();
    
    return 0;
}
