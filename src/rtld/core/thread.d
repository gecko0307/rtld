module rtld.core.thread;

version(Windows)
{
    import rtld.sys.windows.windows;
}
else version(Posix)
{
    import rtld.libc.time;
    import rtld.sys.posix.pthread;
    import rtld.sys.posix.time;
}

/**
 * Base class for creating threads
 */
class Thread
{
   protected:
    
    void function() func;
    void delegate() dlgt;
    bool callFunc;
    bool initialized = false;
    
   public:
    
    version(Windows)
    {
        private void* winThread;
    }
    else version(Posix)
    {
        private pthread_t posixThread;
        private bool running = false;
    }
    
    /// Constructor. Initializes a thread using a function pointer
    this(void function() func) nothrow @nogc
    {
        this.func = func;
        callFunc = true;
    }
    
    /// Constructor. Initializes a thread using a delegate
    this(void delegate() dlgt) nothrow @nogc
    {
        this.dlgt = dlgt;
        callFunc = false;
    }
    
    /// Destructor
    ~this() nothrow @nogc
    {
        version(Windows)
        {
            if (winThread)
                CloseHandle(winThread);
        }
        else version(Posix)
        {
            if (initialized)
                pthread_detach(posixThread);
        }
    }
    
    /// Starts the thread
    void start() nothrow @nogc
    {
        version(Windows)
        {
            if (winThread)
                CloseHandle(winThread);
            uint threadId;
            winThread = CreateThread(null, cast(size_t)0, &winThreadFunc, cast(void*)this, cast(uint)0, &threadId);
            assert(winThread !is null);
            initialized = true;
        }
        else version(Posix)
        {
            running = true;
            int error = pthread_create(&posixThread, null, &posixThreadFunc, cast(void*)this);
            assert(error == 0);
            initialized = true;
        }
    }
    
    /// Waits for the thread to terminate
    void join() nothrow @nogc
    {
        version(Windows)
        {
            WaitForMultipleObjects(1u, &winThread, 1, INFINITE);
        }
        else version(Posix)
        {
            pthread_join(posixThread, null);
        }
    }
    
    /// Checks if thread is running
    bool isRunning() nothrow @nogc
    {
        version(Windows)
        {
            uint c = 0;
            GetExitCodeThread(winThread, &c);
            return (c == STILL_ACTIVE);
        }
        else version(Posix)
        {
            return running;
        }
        else
        {
            return false;
        }
    }
    
    /// Stops the thread immediately. This functionality is unsafe, use with care
    void terminate() nothrow @nogc
    {
        version(Windows)
        {
            TerminateThread(winThread, 1);
        }
        else version(Posix)
        {
            pthread_cancel(posixThread);
        }
    }
    
    version(Windows)
    {
        extern(Windows) static uint winThreadFunc(const(void)* lpParam)
        {
            Thread t = cast(Thread)lpParam;
            if (t.callFunc)
                t.func();
            else
                t.dlgt();
            return 0;
        }
    }
    else version(Posix)
    {
        extern(C) static void* posixThreadFunc(void* arg)
        {
            Thread t = cast(Thread)arg;
            if (t.callFunc)
                t.func();
            else
                t.dlgt();
            t.running = false;
            return null;
        }
    }
    
    /// Wait for specified amout of milliseconds
    static void sleep(uint msec) nothrow @nogc
    {
        version(Windows)
        {
            Sleep(msec);
        }
        else version(Posix)
        {
            timespec ts;
            ts.tv_sec = msec / 1000;
            ts.tv_nsec = (msec % 1000) * 1000000;
            nanosleep(&ts, null);
        }
    }
}
