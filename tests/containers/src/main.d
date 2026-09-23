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
    
    /*
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
    */
    
    Foo[] arr = [Foo(1, 2), Foo(5, 6), Foo(0, 0)];
    printLn(arr);
    
    float[] arr1 = [0.1f, 0.0f, 0.0f];
    printLn(arr1);
    
    int[] arr2 = [100, 50, 85, 10, 5, 99, 0];
    insertionSort!((a, b) => a < b)(arr2);
    printLn(arr2);
    
    printMemoryLeaks();
    
    //auto ti = cast(TypeInfo_Array)typeid(int[]);

    //printFmtLn("ti = {0}", ti);
    //printFmtLn("value = {0}", ti.value);
/*
    auto ti = cast(TypeInfo_Array)typeid(int[]);

    // Приводим указатель на объект к указателю на массив чисел size_t
    size_t* raw = cast(size_t*)cast(void*)ti;

    // Выводим слоты как обычные числа
    printFmtLn("Slot 0 (vtbl): {0}", cast(ulong)raw[0]);
    printFmtLn("Slot 1 (monitor): {0}", cast(ulong)raw[1]);
    printFmtLn("Slot 2: {0}", cast(ulong)raw[2]);
    printFmtLn("Slot 3: {0}", cast(ulong)raw[3]);
    printFmtLn("Slot 4: {0}", cast(ulong)raw[4]);
    printFmtLn("Slot 5: {0}", cast(ulong)raw[5]);

    // Для сравнения выведем id самого типа int, который компилятор должен был записать в value
    printFmtLn("Expected int TypeInfo ID: {0}", cast(ulong)cast(void*)typeid(int));
*/
}
