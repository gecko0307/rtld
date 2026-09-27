module main;

import rtld;

int main()
{
    memoryProfilerEnabled = true;
    
    String jsonStr = String.fromFile("64KB.json");
    
    Stopwatch sw;
    sw.start();
    JSONDocument doc = New!JSONDocument(jsonStr);
    auto t = sw.elapsed();
    printFmtLn("{0} ms", t.milliseconds);
    
    printLn(doc.root);
    
    Delete(doc);
    jsonStr.free();
    
    if (allocatedMemory > 0)
        printMemoryLeaks();
    
    printStr("Success!");
    
    return 0;
}
