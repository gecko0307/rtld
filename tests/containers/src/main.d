module main;

import rtld;

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
}
