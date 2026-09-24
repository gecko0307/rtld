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
    
    override string toString()
    {
        return data;
    }
}

void main()
{
    string name = "Тест";
    int code = 200;
    float num = 0.5f;
    Property prop = Property("Money", 100);
    SomeClass someClass = New!SomeClass("Foo");
    scope(exit)
    {
        destroy(someClass);
    }
    
    printFmtLn("string: {0}, int: {1}, float: {2}, prop: {3}, someClass: {4}", name, code, num, prop, someClass);
    
    string normalStr = "Обычная строка";
    wstring wideStr = "Широкая строка Windows (UTF-16)"w;
    printFmtLn("Unicode: {0} | {1}", normalStr, wideStr);
}
