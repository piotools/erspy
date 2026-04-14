module winapi @if (env::WIN32);

// foundation

const uint MAX_PATH = 260;
const uint MAX_MODULE_NAME32 = 255;

// memory

const uint MEM_COMMIT = 0x00001000;
const uint MEM_RESERVE = 0x00002000;
const uint MEM_RELEASE = 0x00008000;

const uint MEM_PRIVATE = 0x20000;
const uint MEM_MAPPED = 0x40000;
const uint MEM_IMAGE = 0x1000000;

const uint PAGE_READONLY = 0x02;
const uint PAGE_READWRITE = 0x04;
const uint PAGE_EXECUTE_READ = 0x20;
const uint PAGE_EXECUTE_READWRITE = 0x40;
const uint PAGE_EXECUTE_WRITECOPY = 0x80;
const uint PAGE_NOACCESS = 0x01;
const uint PAGE_GUARD = 0x100;

const uint SEC_COMMIT = 0x08000000;

// process

const void* INVALID_HANDLE_VALUE = (void*)uptr.max;

// access masks

const uint SEMAPHORE_ALL_ACCESS = 0x1F0003;
const uint PROCESS_ALL_ACCESS = 0x1F0FFF;
const uint PROCESS_DUP_HANDLE = 0x0040;
const uint SECTION_ALL_ACCESS = 0x000F001F;
const uint DUPLICATE_SAME_ACCESS = 0x00000002;

// others

const uint GENERIC_READ = 0x80000000;
const uint GENERIC_WRITE = 0x40000000;

const uint STILL_ACTIVE = 0x103;

// timer

const uint INFINITE = 0xFFFFFFFF;
