module msvc_ext::pointers;

struct SharedPtr <Type> {
    Type* ptr;
    RefObject* ref_object;
}

struct RefObject {
    void* vftable;
    uint uses;
    uint weaks;
}
