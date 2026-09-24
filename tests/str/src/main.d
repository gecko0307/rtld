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
    printf("%s\n", s1.ptr);
    assert(!s1.isDynamic);
    string dStr = s1;
    assert(dStr == "hello, world!");
    s1.free();
    assert(s1.length == 0);
    
    const(char)* cStr = "Hello!";
    String s2 = String(cStr);
    assert(s2.toString == "Hello!");
    s2.free();
    
    String s3 = String.fromFile("test.txt");
    printf("%s\n", s3.ptr);
    s3.free();
    
    TestClass t = New!TestClass();
    
    int[5] arr = [0, 1, 2, 3, 4];
    String s4 = format("Name: {0}, age: {1}, employed: {2}, weight: {3}, class: {4}, ptr: {5}, arr: {6}", "John Doe", 30, true, 80.0f, t, cast(void*)t, arr);
    printf("%s\n", s4.ptr);
    printf("%d\n", s4.length);
    s4.free();
    
    Delete(t);
    
    if (allocatedMemory > 0)
        printMemoryLeaks();

    return 0;
}
