module rtld.core.window;

version(Windows)
{
    version = WindowsSystemPresent;
}
else version(linux)
{
    version = WindowsSystemPresent;
}

version(WindowsSystemPresent):

import rtld.time.timer;
import rtld.gl.context;

version(Windows)
{
    public import rtld.sys.windows.windows;
}
else version(linux)
{
    public import rtld.sys.linux.x11;
}

struct SystemWindowCreationSettings
{
    uint x;
    uint y;
    uint width;
    uint height;
    const(wchar)* title;
}

struct SystemWindowInfo
{
    version(Windows)
    {
        HWND hwnd;
        HDC hdc;
        WNDCLASSW wc;
        MSG message;
    }
    else version(linux)
    {
        Window window;
        Display* display;
        Screen* screen;
        Window root;
        ulong wmProtocols;
        ulong wmDelete;
        XEvent event;
    }
    
    bool valid = false;
}

struct SystemWindowEvent
{
    version(Windows)
    {
        MSG message;
    }
    else version(linux)
    {
        ulong wmProtocols;
        ulong wmDelete;
        XEvent xEvent;
    }
}

class SystemWindow
{
    SystemWindowCreationSettings settings;
    SystemWindowInfo info;
    protected SystemWindowEvent event;
    bool glPresent = false;
    OpenGLVersion glVersion;
    GLContext glContext;
    
    uint x = 0;
    uint y = 0;
    uint width = 0;
    uint height = 0;
    bool running = false;
    
    double timer = 0.0;
    double timeStep = 1.0 / 60.0;
    
    this(SystemWindowCreationSettings* settings)
    {
        this.settings = *settings;
        this.x = settings.x;
        this.y = settings.y;
        this.width = settings.width;
        this.height = settings.height;
        
        version(Windows)
        {
            info.wc.style = 0;
            info.wc.lpfnWndProc = &WndProc;
            info.wc.cbClsExtra = 0;
            info.wc.cbWndExtra = 0;
            info.wc.hInstance = GetModuleHandle(null);
            info.wc.hIcon = null;
            info.wc.hCursor = LoadCursor(null, IDC_ARROW);
            //info.wc.hbrBackground = cast(HBRUSH)(COLOR_WINDOW + 1);
            info.wc.hbrBackground = cast(HBRUSH)GetStockObject(BLACK_BRUSH);
            info.wc.lpszMenuName = null;
            info.wc.lpszClassName = "RTLDWindow"w.ptr;

            if (RegisterClassW(&info.wc) == 0)
                return;
            
            uint style = WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN;
            RECT rect;
            rect.left = settings.x;
            rect.top = settings.y;
            rect.right = settings.x + settings.width;
            rect.bottom = settings.y + settings.height;
            AdjustWindowRectEx(&rect, style, FALSE, 0);
            int finalWidth = rect.right - rect.left;
            int finalHeight = rect.bottom - rect.top;

            info.hwnd = CreateWindowExW(
                0,
                info.wc.lpszClassName,
                settings.title,
                WS_OVERLAPPEDWINDOW | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
                settings.x, settings.y,
                finalWidth, finalHeight,
                null,
                null,
                info.wc.hInstance,
                cast(void*)this
            );
            
            info.hdc = GetDC(info.hwnd);
        }
        else version(linux)
        {
            info.display = XOpenDisplay(null);
            if (info.display is null)
                return;
            
            info.screen = XDefaultScreenOfDisplay(info.display);
            info.root = XRootWindowOfScreen(info.screen);
            
            info.window = XCreateSimpleWindow(
                info.display, info.root,
                settings.x, settings.y,
                settings.width, settings.height,
                0, 0, 0);
            
            XSelectInput(info.display, info.window, StructureNotifyMask);
            
            event.wmProtocols = XInternAtom(info.display, "WM_PROTOCOLS", 0);
            event.wmDelete = XInternAtom(info.display, "WM_DELETE_WINDOW", 0);
            XSetWMProtocols(info.display, info.window, &event.wmDelete, 1);
            
            XSetWindowBackground(info.display, info.window, 0x000000);
            XClearWindow(info.display, info.window);
            XMapWindow(info.display, info.window);
            XFlush(info.display);
        }
        
        info.valid = true;
        this.running = true;
    }
    
    bool createGLContext(OpenGLVersion glVersion) nothrow @nogc
    {
        if (!info.valid)
            return false;
        
        GLDevice glDevice;
        version(Windows)
        {
            glDevice = GLDevice(info.hdc);
        }
        else version(linux)
        {
            glDevice = GLDevice(info.display, info.window);
        }
        auto context = loadOpenGL(glDevice, glVersion);
        if (isValidGLContext(context))
        {
            this.glVersion = glVersion;
            this.glContext = context;
            this.glPresent = true;
            return true;
        }
        else
        {
            this.glPresent = false;
            return false;
        }
    }
    
    protected void dispatch()
    {
        if (!running || !info.valid)
            return;
        
        version(Windows)
        {
            while(PeekMessage(&event.message, null, 0, 0, PM_REMOVE) != 0)
            {
                if (event.message.message == WM_QUIT)
                {
                    running = false;
                }
                
                TranslateMessage(&event.message);
                DispatchMessage(&event.message);
            }
        }
        else version(linux)
        {
            while(XPending(info.display) > 0)
            {
                XNextEvent(info.display, &event.xEvent);
                
                if (event.xEvent.type == ClientMessage &&
                    event.xEvent.xclient.messageType == event.wmProtocols &&
                    cast(ulong)event.xEvent.xclient.data[0] == event.wmDelete)
                {
                    running = false;
                }
                else if (event.xEvent.type == ConfigureNotify)
                {
                    XConfigureEvent xce = event.xEvent.xconfigure;
                    if (xce.width != width || xce.height != height)
                    {
                        width = cast(uint)xce.width;
                        height = cast(uint)xce.height;
                        onResize(width, height);
                    }
                }
            }
        }
    }
    
    protected void swapBuffers() nothrow @nogc
    {
        if (!glPresent)
            return;
        
        version(Windows)
        {
            SwapBuffers(info.hdc);
        }
        else version(linux)
        {
            eglSwapBuffers(glContext.display, glContext.surface);
        }
    }
    
    void run()
    {
        timer = getTimeStep();
        
        while(running)
        {
            dispatch();
            
            double timeStep = getTimeStep();
            timer += timeStep;
            if (timer >= timeStep)
            {
                timer -= timeStep;
                onUpdate(timeStep);
            }
        }
        
        onQuit();
        
        version(linux)
        {
            if (info.valid)
            {
                XDestroyWindow(info.display, info.window);
                XCloseDisplay(info.display);
            }
        }
    }
    
    void onUpdate(double dt) {}
    void onQuit() {}
    void onResize(uint width, uint height) {}
}

version(Windows)
{
    extern(Windows) LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
    {
        if (msg == WM_NCCREATE)
        {
            auto createStruct = cast(CREATESTRUCT*)lParam;
            SystemWindow window = cast(SystemWindow)createStruct.lpCreateParams;
            SetWindowLongPtr(hwnd, GWLP_USERDATA, cast(LONG_PTR)cast(void*)window);
            return TRUE;
        }
        
        SystemWindow window = cast(SystemWindow)cast(void*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
        if (window is null)
            return DefWindowProc(hwnd, msg, wParam, lParam);
        
        switch(msg)
        {
            case WM_DESTROY:
                PostQuitMessage(0);
                return 0;
            case WM_SIZE:
                window.width = cast(uint)(lParam & 0xFFFF);
                window.height = cast(uint)(lParam >> 16);
                if (window.running)
                    window.onResize(window.width, window.height);
                return 0;
            default:
                break;
        }
        
        return DefWindowProc(hwnd, msg, wParam, lParam);
    }
}
