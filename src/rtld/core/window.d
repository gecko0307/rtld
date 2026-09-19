module rtld.core.window;

version(Windows):

public import rtld.sys.windows.windows;

enum WindowStateSignal
{
    None = 0,
    Resize = 1
}

struct WindowState
{
    int width;
    int height;
    const(wchar)* title;
    WindowStateSignal ss;
}

extern(Windows) LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) @nogc nothrow
{
    if (msg == WM_NCCREATE)
    {
        auto createStruct = cast(CREATESTRUCT*)lParam;
        auto windowState = cast(WindowState*)createStruct.lpCreateParams;
        SetWindowLongPtr(hwnd, GWLP_USERDATA, cast(LONG_PTR)windowState);
        return TRUE;
    }
    
    auto windowState = cast(WindowState*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if (windowState is null)
        return DefWindowProc(hwnd, msg, wParam, lParam);
    
    switch (msg)
    {
        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
        case WM_SIZE:
            windowState.width = lParam & 0xFFFF;
            windowState.height = cast(int)(lParam >> 16);
            windowState.ss = WindowStateSignal.Resize;
            return 0;
        default:
            break;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

HWND createWindow(
    uint width,
    uint height,
    const(wchar)* title,
    WindowState* windowState) @nogc nothrow
{
    WNDCLASSW wc;

    wc.style = 0;
    wc.lpfnWndProc = &WndProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hInstance = GetModuleHandle(null);
    wc.hIcon = null;
    wc.hCursor = LoadCursor(null, IDC_ARROW);
    wc.hbrBackground = cast(HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszMenuName = null;
    wc.lpszClassName = "DcoreWindow"w.ptr;

    if (RegisterClassW(&wc) == 0)
        return null;

    HWND hwnd = CreateWindowExW(
        0,
        wc.lpszClassName,
        title,
        WS_OVERLAPPEDWINDOW |
        WS_VISIBLE |
        WS_CLIPSIBLINGS |
        WS_CLIPCHILDREN,
        100, 100,
        width, height,
        null,
        null,
        wc.hInstance,
        windowState
    );

    return hwnd;
}

private
{
    __gshared MSG w_msg;
}

alias EventDispatchCallback = void function(MSG*, void*) @nogc nothrow;

void dispatchMessage(EventDispatchCallback callback, void* userData) @nogc nothrow
{
    while (PeekMessage(&w_msg, null, 0, 0, PM_REMOVE) != 0)
    {
        if (callback)
            callback(&w_msg, userData);
        TranslateMessage(&w_msg);
        DispatchMessage(&w_msg);
    }
}
