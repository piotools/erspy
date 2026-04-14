module user32;

const void* HWND_TOPMOST = (void*)(uptr)-1;
const void* HWND_NOTOPMOST = (void*)(uptr)-2;
const uint SWP_NOSIZE = 0x0001;
const uint SWP_NOMOVE = 0x0002;

extern fn bool set_window_pos(
    void* window,
    void* window_insert_after,
    int x,
    int y,
    int cx,
    int cy,
    uint flags
) @cname("SetWindowPos");
