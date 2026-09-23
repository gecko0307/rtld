module main;

import rtld;

void main()
{
    Array!int arr;
    scope(exit)
    {
        arr.free();
    }
    
    arr.append(100);
    arr.append(5);
    
    printLn(arr.data);
    
    FlatHashMap!int hashMap = New!(FlatHashMap!int)();
    hashMap["foo"] = 10;
    hashMap["bar"] = 20;
    printLn(hashMap["foo"]);
    printLn(hashMap["bar"]);
    Delete(hashMap);
}
