module main;

import rtld;

class TestClass
{
}

int main()
{
    memoryProfilerEnabled = true;
    
    String s1 = "Hello";
    s1 ~= ", World";
    s1 ~= '!';
    printLn(s1);
    assert(!s1.isDynamic);
    string dStr = s1;
    assert(dStr == "Hello, World!");
    s1.free();
    assert(s1.length == 0);
    
    const(char)* cStr = "Hello!";
    String s2 = String(cStr);
    assert(s2.toString == "Hello!");
    s2.free();
    
    String s3 = String.fromFile("test.txt");
    printLn(s3);
    s3.free();
    
    TestClass t = New!TestClass();
    
    int[5] arr = [0, 1, 2, 3, 4];
    String s4 = format("Name: {0}, age: {1}, hex: 0x{1:X}, employed: {2}, weight: {3}, class: {4}, ptr: {5}, arr: {6}",
        "John Doe",
        30,
        true,
        80.0f,
        t,
        cast(void*)t,
        arr);
    printLn(s4);
    printLn(s4.length);
    s4.free();
    
    Delete(t);
    
    if (allocatedMemory > 0)
        printMemoryLeaks();

    return 0;
}
