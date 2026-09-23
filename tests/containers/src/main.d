module main;

import rtld;

struct Foo
{
    int x;
    int y;
}

void main()
{
    memoryProfilerEnabled = true;
    
    // Dynamic array
    {
        Array!int arr;
        arr.append(100);
        arr.append(5);
        printLn(arr.data);
        arr.free();
    }
    
    // Hash map
    {
        FlatHashMap!int hashMap = New!(FlatHashMap!int)();
        hashMap["foo"] = 10;
        hashMap["bar"] = 20;
        printLn(hashMap["foo"]);
        printLn(hashMap["bar"]);
        Delete(hashMap);
    }
    
    // Literals
    {
        Foo[] arr = [Foo(1, 2), Foo(5, 6), Foo(0, 0)];
        printLn(arr);
        
        float[] arr1 = [0.1f, 0.0f, 0.0f];
        printLn(arr1);
        
        int[] arr2 = [100, 50, 85, 10, 5, 99, 0];
        insertionSort!((a, b) => a < b)(arr2);
        printLn(arr2);
    }
    
    // Should print leaked literals
    printMemoryLeaks();
}
