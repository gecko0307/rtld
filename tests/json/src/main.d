module main;

import rtld;

int main()
{
    String jsonStr = String.fromFile("64KB.json");
    JSONDocument doc = New!JSONDocument(jsonStr);
    
    printLn(doc.root);
    
    Delete(doc);
    jsonStr.free();
    
    if (allocatedMemory > 0)
        printMemoryLeaks();
    
    return 0;
}
