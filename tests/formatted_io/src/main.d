module main;

import rtld;

struct Property
{
    string name;
    int value;
}

class SomeClass
{
    string data;
    
    this(string data)
    {
        this.data = data;
    }
    
    void print(OutputStream stream) @nogc nothrow
    {
        .printFmt(stream, "SomeClass: {0}", data);
    }
}

int main()
{
    string name = "Тест";
    int code = 200;
    float num = 0.5f;
    Property prop = Property("Money", 100);
    printFmtLn("string: {0}, int: {1}, float: {2}, prop: {3}", name, code, num, prop);
    
    string normalStr = "Обычная строка";
    wstring wideStr = "Широкая строка Windows (UTF-16)"w;
    printFmtLn("Unicode: {0} | {1}", normalStr, wideStr);
    
    SomeClass someClass = New!SomeClass("Foo");
    scope(exit)
    {
        Delete(someClass);
    }
    printLn(someClass);
    
    auto openResult = File.open("test.txt", FileAccessMode.Write);
    if (!openResult.success)
        return 1;
    File file = openResult.value;
    file.printLn("Hello, World!");
    file.printFmtLn("string: {0}, int: {1}, float: {2}, prop: {3}", name, code, num, prop);
    file.printFmtLn("Unicode: {0} | {1}", normalStr, wideStr);
    file.close();
    
    return 0;
}
