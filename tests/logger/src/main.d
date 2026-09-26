module main;

import rtld;

int main()
{
    
    LogOutputOptions logOptions = {
        enabled: true,
        printToStdout: true,
        printToFile: true,
        printToBuffer: false,
        printTimestamp: true,
        printLogLevel: true,
        filename: "app.log"
    };
    setLogOutputOptions(&logOptions);
    
    int value = 10;
    
    logInfo("Hello, World!");
    logDebug("value = ", value);
    
    return 0;
}
