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
    
    printLn(doc.root);
    size_t docSize = doc.allocationSize;
    
    Delete(doc);
    jsonStr.free();
    
    if (allocatedMemory > 0)
        printMemoryLeaks();
    
    printLn("Success!");
    printFmtLn("Parsed in {0} ms", t.milliseconds);
    printFmtLn("Document used {0} byte(s)", docSize);
    
    return 0;
}

