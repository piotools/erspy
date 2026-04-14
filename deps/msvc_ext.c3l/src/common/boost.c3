module msvc_ext::boost_ext;

import msvc_ext;

struct BoostFunction {
    void* vftable;
    SharedPtr{void*} func;
}
