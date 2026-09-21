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
}
