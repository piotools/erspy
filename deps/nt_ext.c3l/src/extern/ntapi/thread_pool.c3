module ntapi @if (env::WIN32);

struct TpTasksCallbacks {
    void* execute_callback;
    void* unposted;
}

struct TpTask {
    TpTasksCallbacks* callbacks;
    uint numa_node;
    char ideal_processor;
    char[3] padding;
    ListEntry list_entry;
}

struct TpDirect {
    TpTask task;
    ulong lock;
    ListEntry io_completion_information_list;
    void* callback;
    uint numa_node;
    char ideal_processor;
    char[3] padding;
}
