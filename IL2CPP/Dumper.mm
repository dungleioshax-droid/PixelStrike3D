#import <Foundation/Foundation.h>
#include "Dumper.h"
#include "../IMGUI/Il2cpp.h"
#include <fstream>
#include <sstream>
#include <ctime>
#include <cstring>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <unistd.h>

// ---------- trạng thái global ----------
static bool g_isDumping = false;
static std::string g_status = "Chua dump. Nhan [Dump Now] de dump Unity ra Documents.";
static std::string g_lastPath = "";

// ---------- function pointer đúng kiểu cho dump ----------
typedef void* (*Fn_domain_get)();
typedef void** (*Fn_domain_get_assemblies)(const void*, size_t*);
typedef const void* (*Fn_assembly_get_image)(const void*);
typedef const char* (*Fn_image_get_name)(void*);
typedef void* (*Fn_image_get_class)(void*, size_t);
typedef size_t (*Fn_image_get_class_count)(void*);
typedef const char* (*Fn_class_get_name)(void*);
typedef const char* (*Fn_class_get_namespace)(void*);
typedef void* (*Fn_class_get_methods)(void*, void**);
typedef const char* (*Fn_method_get_name)(void*);
typedef uint32_t (*Fn_method_get_flags)(void*, uint32_t*);
typedef void* (*Fn_method_get_return_type)(void*);
typedef int32_t (*Fn_method_get_param_count)(void*);
typedef void* (*Fn_method_get_param)(void*, uint32_t);
typedef const char* (*Fn_method_get_param_name)(void*, uint32_t);
typedef void* (*Fn_class_get_fields)(void*, void**);
typedef const char* (*Fn_field_get_name)(void*);
typedef size_t (*Fn_field_get_offset)(void*);
typedef int32_t (*Fn_field_get_flags)(void*);
typedef void* (*Fn_field_get_type)(void*);
typedef char* (*Fn_type_get_name)(void*);
typedef void (*Fn_free)(void*);

static Fn_domain_get p_domain_get = nullptr;
static Fn_domain_get_assemblies p_domain_get_assemblies = nullptr;
static Fn_assembly_get_image p_assembly_get_image = nullptr;
static Fn_image_get_name p_image_get_name = nullptr;
static Fn_image_get_class p_image_get_class = nullptr;
static Fn_image_get_class_count p_image_get_class_count = nullptr;
static Fn_class_get_name p_class_get_name = nullptr;
static Fn_class_get_namespace p_class_get_namespace = nullptr;
static Fn_class_get_methods p_class_get_methods = nullptr;
static Fn_method_get_name p_method_get_name = nullptr;
static Fn_method_get_flags p_method_get_flags = nullptr;
static Fn_method_get_return_type p_method_get_return_type = nullptr;
static Fn_method_get_param_count p_method_get_param_count = nullptr;
static Fn_method_get_param p_method_get_param = nullptr;
static Fn_method_get_param_name p_method_get_param_name = nullptr;
static Fn_class_get_fields p_class_get_fields = nullptr;
static Fn_field_get_name p_field_get_name = nullptr;
static Fn_field_get_offset p_field_get_offset = nullptr;
static Fn_field_get_flags p_field_get_flags = nullptr;
static Fn_field_get_type p_field_get_type = nullptr;
static Fn_type_get_name p_type_get_name = nullptr;
static Fn_free p_il2cpp_free = nullptr;

static void* DumpResolve(const char* name) {
    void* p = dlsym(RTLD_DEFAULT, name);
    // fallback: thử lấy từ IL2Cpp:: namespace đã Attach (nếu có)
    return p;
}

static bool ResolveDumpSymbols() {
    // Nếu đã resolve đủ core thì thôi
    if (p_domain_get && p_domain_get_assemblies && p_assembly_get_image &&
        p_image_get_class && p_image_get_class_count) {
        return true;
    }
    // Đảm bảo IL2Cpp::Attach() đã chạy để load UnityFramework symbols
    @try {
        IL2Cpp::Attach();
    } @catch (...) {}

    p_domain_get = (Fn_domain_get)DumpResolve("il2cpp_domain_get");
    if (!p_domain_get && IL2Cpp::il2cpp_domain_get)
        p_domain_get = (Fn_domain_get)(void*)IL2Cpp::il2cpp_domain_get;

    p_domain_get_assemblies = (Fn_domain_get_assemblies)DumpResolve("il2cpp_domain_get_assemblies");
    if (!p_domain_get_assemblies && IL2Cpp::il2cpp_domain_get_assemblies)
        p_domain_get_assemblies = (Fn_domain_get_assemblies)(void*)IL2Cpp::il2cpp_domain_get_assemblies;

    p_assembly_get_image = (Fn_assembly_get_image)DumpResolve("il2cpp_assembly_get_image");
    if (!p_assembly_get_image && IL2Cpp::il2cpp_assembly_get_image)
        p_assembly_get_image = (Fn_assembly_get_image)(void*)IL2Cpp::il2cpp_assembly_get_image;

    p_image_get_name = (Fn_image_get_name)DumpResolve("il2cpp_image_get_name");
    if (!p_image_get_name && IL2Cpp::il2cpp_image_get_name)
        p_image_get_name = (Fn_image_get_name)(void*)IL2Cpp::il2cpp_image_get_name;

    p_image_get_class = (Fn_image_get_class)DumpResolve("il2cpp_image_get_class");
    if (!p_image_get_class && IL2Cpp::il2cpp_image_get_class)
        p_image_get_class = (Fn_image_get_class)(void*)IL2Cpp::il2cpp_image_get_class;

    p_image_get_class_count = (Fn_image_get_class_count)DumpResolve("il2cpp_image_get_class_count");
    if (!p_image_get_class_count && IL2Cpp::il2cpp_image_get_class_count)
        p_image_get_class_count = (Fn_image_get_class_count)(void*)IL2Cpp::il2cpp_image_get_class_count;

    p_class_get_name = (Fn_class_get_name)DumpResolve("il2cpp_class_get_name");
    if (!p_class_get_name && IL2Cpp::il2cpp_class_get_name)
        p_class_get_name = (Fn_class_get_name)(void*)IL2Cpp::il2cpp_class_get_name;

    p_class_get_namespace = (Fn_class_get_namespace)DumpResolve("il2cpp_class_get_namespace");
    if (!p_class_get_namespace && IL2Cpp::il2cpp_class_get_namespace)
        p_class_get_namespace = (Fn_class_get_namespace)(void*)IL2Cpp::il2cpp_class_get_namespace;

    p_class_get_methods = (Fn_class_get_methods)DumpResolve("il2cpp_class_get_methods");
    if (!p_class_get_methods && IL2Cpp::il2cpp_class_get_methods)
        p_class_get_methods = (Fn_class_get_methods)(void*)IL2Cpp::il2cpp_class_get_methods;

    p_method_get_name = (Fn_method_get_name)DumpResolve("il2cpp_method_get_name");
    if (!p_method_get_name && IL2Cpp::il2cpp_method_get_name)
        p_method_get_name = (Fn_method_get_name)(void*)IL2Cpp::il2cpp_method_get_name;

    p_method_get_flags = (Fn_method_get_flags)DumpResolve("il2cpp_method_get_flags");
    if (!p_method_get_flags && IL2Cpp::il2cpp_method_get_flags)
        p_method_get_flags = (Fn_method_get_flags)(void*)IL2Cpp::il2cpp_method_get_flags;

    p_method_get_return_type = (Fn_method_get_return_type)DumpResolve("il2cpp_method_get_return_type");
    if (!p_method_get_return_type && IL2Cpp::il2cpp_method_get_return_type)
        p_method_get_return_type = (Fn_method_get_return_type)(void*)IL2Cpp::il2cpp_method_get_return_type;

    p_method_get_param_count = (Fn_method_get_param_count)DumpResolve("il2cpp_method_get_param_count");
    if (!p_method_get_param_count && IL2Cpp::il2cpp_method_get_param_count)
        p_method_get_param_count = (Fn_method_get_param_count)(void*)IL2Cpp::il2cpp_method_get_param_count;

    p_method_get_param = (Fn_method_get_param)DumpResolve("il2cpp_method_get_param");
    if (!p_method_get_param && IL2Cpp::il2cpp_method_get_param)
        p_method_get_param = (Fn_method_get_param)(void*)IL2Cpp::il2cpp_method_get_param;

    p_method_get_param_name = (Fn_method_get_param_name)DumpResolve("il2cpp_method_get_param_name");
    if (!p_method_get_param_name && IL2Cpp::il2cpp_method_get_param_name)
        p_method_get_param_name = (Fn_method_get_param_name)(void*)IL2Cpp::il2cpp_method_get_param_name;

    p_class_get_fields = (Fn_class_get_fields)DumpResolve("il2cpp_class_get_fields");
    if (!p_class_get_fields && IL2Cpp::il2cpp_class_get_fields)
        p_class_get_fields = (Fn_class_get_fields)(void*)IL2Cpp::il2cpp_class_get_fields;

    p_field_get_name = (Fn_field_get_name)DumpResolve("il2cpp_field_get_name");
    if (!p_field_get_name && IL2Cpp::il2cpp_field_get_name)
        p_field_get_name = (Fn_field_get_name)(void*)IL2Cpp::il2cpp_field_get_name;

    p_field_get_offset = (Fn_field_get_offset)DumpResolve("il2cpp_field_get_offset");
    if (!p_field_get_offset && IL2Cpp::il2cpp_field_get_offset)
        p_field_get_offset = (Fn_field_get_offset)(void*)IL2Cpp::il2cpp_field_get_offset;

    p_field_get_flags = (Fn_field_get_flags)DumpResolve("il2cpp_field_get_flags");
    if (!p_field_get_flags && IL2Cpp::il2cpp_field_get_flags)
        p_field_get_flags = (Fn_field_get_flags)(void*)IL2Cpp::il2cpp_field_get_flags;

    // il2cpp_field_get_type trong project khai báo sai kiểu (const char*), nên resolve trực tiếp
    p_field_get_type = (Fn_field_get_type)DumpResolve("il2cpp_field_get_type");

    p_type_get_name = (Fn_type_get_name)DumpResolve("il2cpp_type_get_name");
    if (!p_type_get_name && IL2Cpp::il2cpp_type_get_name)
        p_type_get_name = (Fn_type_get_name)(void*)IL2Cpp::il2cpp_type_get_name;

    p_il2cpp_free = (Fn_free)DumpResolve("il2cpp_free");

    return (p_domain_get && p_domain_get_assemblies && p_assembly_get_image);
}

static void SafeFreeTypeName(char* s) {
    if (!s) return;
    if (p_il2cpp_free) {
        @try { p_il2cpp_free(s); } @catch (...) { free(s); }
    } else {
        free(s);
    }
}

static uint64_t GetUnityFrameworkBase(const char** outName) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (!name) continue;
        std::string s(name);
        if (s.find("UnityFramework") != std::string::npos) {
            const struct mach_header* hdr = _dyld_get_image_header(i);
            if (outName) *outName = name;
            return (uint64_t)hdr; // base đã ASLR
        }
    }
    // fallback: thử tìm binary chính của game
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (!name) continue;
        std::string s(name);
        if (s.find(".app/") != std::string::npos) {
            const struct mach_header* hdr = _dyld_get_image_header(i);
            if (outName) *outName = name;
            return (uint64_t)hdr;
        }
    }
    return 0;
}

bool UnityDumper_IsDumping() { return g_isDumping; }
std::string UnityDumper_GetStatus() { return g_status; }
std::string UnityDumper_GetLastPath() { return g_lastPath; }

bool UnityDumper_DumpNow(std::string &outPath, std::string &outMsg) {
    @autoreleasepool {
        if (!ResolveDumpSymbols()) {
            outMsg = "FAIL: khong resolve duoc il2cpp symbols (game chua load IL2CPP?). Thu lai khi dang o trong tran.";
            return false;
        }
        // ---- Documents path ----
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docs = [paths firstObject];
        if (!docs) {
            outMsg = "FAIL: khong lay duoc Documents path.";
            return false;
        }
        NSString* fileName = @"PixelStrike3D_dump.txt";
        NSString* fullPath = [docs stringByAppendingPathComponent:fileName];
        outPath = std::string([fullPath UTF8String]);

        // ---- game info ----
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* bId = [bundle bundleIdentifier] ?: @"unknown.bundle";
        NSString* disp = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if (!disp) disp = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
        if (!disp) disp = @"Unknown";
        NSString* ver = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        if (!ver) ver = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (!ver) ver = @"?";

        const char* unityImgName = nullptr;
        uint64_t unityBase = GetUnityFrameworkBase(&unityImgName);
        intptr_t slide = 0;
        {
            uint32_t c = _dyld_image_count();
            for (uint32_t i = 0; i < c; i++) {
                const char* n = _dyld_get_image_name(i);
                if (n && unityImgName && strcmp(n, unityImgName) == 0) {
                    slide = _dyld_get_image_vmaddr_slide(i);
                    break;
                }
            }
        }

        std::ofstream out(outPath, std::ios::out | std::ios::trunc);
        if (!out.is_open()) {
            outMsg = std::string("FAIL: khong mo duoc file de ghi: ") + outPath;
            return false;
        }

        time_t now = time(nullptr);
        char timeBuf[64] = {0};
        strftime(timeBuf, sizeof(timeBuf), "%Y-%m-%d %H:%M:%S", localtime(&now));

        out << "// ============================================\n";
        out << "// PixelStrike3D Unity IL2CPP Dump\n";
        out << "// Game: " << [disp UTF8String] << " (" << [bId UTF8String] << ") v" << [ver UTF8String] << "\n";
        out << "// Time: " << timeBuf << "\n";
        out << "// UnityFramework: " << (unityImgName ? unityImgName : "not-found") << "\n";
        out << "// Base(VA): 0x" << std::hex << unityBase << std::dec << "  Slide: 0x" << std::hex << (uint64_t)slide << std::dec << "\n";
        out << "// RVA = MethodVA - Base  |  Offset file ~ RVA (ARM64)\n";
        out << "// Path: " << outPath << "\n";
        out << "// ============================================\n\n";

        void* domain = nullptr;
        @try { domain = p_domain_get(); } @catch (...) { domain = nullptr; }
        if (!domain) {
            out << "// FAIL: il2cpp_domain_get() == null (IL2CPP chua init). Vao tran roi dump lai.\n";
            out.close();
            outMsg = "FAIL: IL2CPP domain null. Hay vao tran/lobby roi Dump lai.";
            return false;
        }

        size_t asmCount = 0;
        void** assemblies = nullptr;
        @try { assemblies = p_domain_get_assemblies(domain, &asmCount); } @catch (...) { assemblies = nullptr; }
        if (!assemblies || asmCount == 0) {
            out << "// FAIL: khong lay duoc assemblies.\n";
            out.close();
            outMsg = "FAIL: khong lay duoc assemblies.";
            return false;
        }

        char header[512];
        snprintf(header, sizeof(header), "// Assemblies: %zu\n", asmCount);
        out << header;

        size_t totalClasses = 0, totalMethods = 0, totalFields = 0;

        for (size_t ai = 0; ai < asmCount; ai++) {
            void* asmPtr = assemblies[ai];
            if (!asmPtr) continue;
            void* image = nullptr;
            @try { image = (void*)p_assembly_get_image(asmPtr); } @catch (...) { continue; }
            if (!image) continue;
            const char* imgName = "unknown";
            @try {
                if (p_image_get_name) {
                    const char* n = p_image_get_name(image);
                    if (n) imgName = n;
                }
            } @catch (...) {}

            size_t classCount = 0;
            @try {
                if (p_image_get_class_count) classCount = p_image_get_class_count(image);
            } @catch (...) { continue; }

            {
                char buf[1024];
                snprintf(buf, sizeof(buf), "\n\n========== Image: %s  (classCount=%zu) ==========\n", imgName, classCount);
                out << buf;
                g_status = std::string("Dumping ") + imgName + " (" + std::to_string(ai+1) + "/" + std::to_string(asmCount) + ")...";
            }

            for (size_t ci = 0; ci < classCount; ci++) {
                void* klass = nullptr;
                @try { klass = p_image_get_class(image, ci); } @catch (...) { continue; }
                if (!klass) continue;

                const char* kName = nullptr;
                const char* kNs = nullptr;
                @try {
                    if (p_class_get_name) kName = p_class_get_name(klass);
                    if (p_class_get_namespace) kNs = p_class_get_namespace(klass);
                } @catch (...) { continue; }
                if (!kName) continue;
                if (!kNs) kNs = "";

                // parent via struct (tránh cần thêm API)
                const char* parentName = "";
                const char* parentNs = "";
                @try {
                    Il2CppClass* kc = (Il2CppClass*)klass;
                    Il2CppClass* parent = kc->_1.parent;
                    if (parent && p_class_get_name) {
                        const char* pn = p_class_get_name((void*)parent);
                        if (pn) parentName = pn;
                        if (p_class_get_namespace) {
                            const char* pns = p_class_get_namespace((void*)parent);
                            if (pns) parentNs = pns;
                        }
                    }
                } @catch (...) {}

                totalClasses++;
                out << "\n// ----- Class: ";
                if (strlen(kNs) > 0) out << kNs << ".";
                out << kName;
                if (strlen(parentName) > 0) {
                    out << " : ";
                    if (strlen(parentNs) > 0) out << parentNs << ".";
                    out << parentName;
                }
                out << "  [" << imgName << "]\n";

                // ---- Fields ----
                if (p_class_get_fields && p_field_get_name) {
                    void* iter = nullptr;
                    int fIdx = 0;
                    while (true) {
                        void* field = nullptr;
                        @try { field = p_class_get_fields(klass, &iter); } @catch (...) { break; }
                        if (!field) break;
                        const char* fName = nullptr;
                        @try { fName = p_field_get_name(field); } @catch (...) { continue; }
                        if (!fName) continue;

                        size_t off = 0;
                        @try { if (p_field_get_offset) off = p_field_get_offset(field); } @catch (...) {}

                        int32_t flags = 0;
                        @try { if (p_field_get_flags) flags = p_field_get_flags(field); } @catch (...) {}

                        char* typeName = nullptr;
                        @try {
                            if (p_field_get_type && p_type_get_name) {
                                void* fType = p_field_get_type(field);
                                if (fType) typeName = p_type_get_name(fType);
                            }
                        } @catch (...) { typeName = nullptr; }

                        char fbuf[2048];
                        snprintf(fbuf, sizeof(fbuf), "  [F_%d] off=0x%zx (dec %zu) flags=0x%x type=%s name=%s\n",
                            fIdx, off, off, flags,
                            typeName ? typeName : "?",
                            fName);
                        out << fbuf;
                        if (typeName) SafeFreeTypeName(typeName);
                        fIdx++;
                        totalFields++;
                    }
                }

                // ---- Methods ----
                if (p_class_get_methods && p_method_get_name) {
                    void* iter = nullptr;
                    int mIdx = 0;
                    while (true) {
                        void* method = nullptr;
                        @try { method = p_class_get_methods(klass, &iter); } @catch (...) { break; }
                        if (!method) break;
                        const char* mName = nullptr;
                        @try { mName = p_method_get_name(method); } @catch (...) { continue; }
                        if (!mName) continue;

                        MethodInfo* mi = (MethodInfo*)method;
                        uint64_t va = 0;
                        @try { va = (uint64_t)mi->methodPointer; } @catch (...) { va = 0; }
                        uint64_t rva = (unityBase && va > unityBase) ? (va - unityBase) : 0;

                        uint32_t iflags = 0;
                        uint32_t flags = 0;
                        @try { if (p_method_get_flags) flags = p_method_get_flags(method, &iflags); } @catch (...) {}

                        int32_t pc = 0;
                        @try { if (p_method_get_param_count) pc = p_method_get_param_count(method); } @catch (...) {}

                        char* retName = nullptr;
                        @try {
                            if (p_method_get_return_type && p_type_get_name) {
                                void* rt = p_method_get_return_type(method);
                                if (rt) retName = p_type_get_name(rt);
                            }
                        } @catch (...) { retName = nullptr; }

                        char mbuf[4096];
                        snprintf(mbuf, sizeof(mbuf), "  [M_%d] RVA=0x%llx VA=0x%llx flags=0x%x ret=%s name=%s params(%d)=",
                            mIdx, (unsigned long long)rva, (unsigned long long)va,
                            flags, retName ? retName : "?",
                            mName, (int)pc);
                        out << mbuf;
                        if (retName) SafeFreeTypeName(retName);

                        out << "(";
                        for (int32_t pi = 0; pi < pc; pi++) {
                            char* ptName = nullptr;
                            const char* pn = "";
                            @try {
                                if (p_method_get_param && p_type_get_name) {
                                    void* pt = p_method_get_param(method, (uint32_t)pi);
                                    if (pt) ptName = p_type_get_name(pt);
                                }
                                if (p_method_get_param_name) {
                                    const char* tmp = p_method_get_param_name(method, (uint32_t)pi);
                                    if (tmp) pn = tmp;
                                }
                            } @catch (...) {}
                            out << (ptName ? ptName : "?") << " " << pn;
                            if (ptName) SafeFreeTypeName(ptName);
                            if (pi + 1 < pc) out << ", ";
                        }
                        out << ")\n";
                        mIdx++;
                        totalMethods++;
                    }
                }
            }
        }

        out << "\n\n// ============ SUMMARY ============\n";
        out << "// Images(classes containers): " << asmCount << "\n";
        out << "// TotalClasses: " << totalClasses << "\n";
        out << "// TotalMethods: " << totalMethods << "\n";
        out << "// TotalFields: " << totalFields << "\n";
        out << "// Done: " << timeBuf << "\n";
        out.close();

        outMsg = "Dump xong! Classes=" + std::to_string(totalClasses) +
                 " Methods=" + std::to_string(totalMethods) +
                 " Fields=" + std::to_string(totalFields) +
                 "\nFile: " + outPath;
        return true;
    }
}

void UnityDumper_StartDump() {
    if (g_isDumping) {
        g_status = "Dang dump... cho chut, dung spam nut!";
        return;
    }
    g_isDumping = true;
    g_status = "Bat dau dump... cho chut (game co the lag vai giay)...";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            std::string path, msg;
            bool ok = false;
            @try {
                ok = UnityDumper_DumpNow(path, msg);
            } @catch (...) {
                msg = "FAIL: crash khi dump (thu lai trong tran).";
                ok = false;
            }
            g_lastPath = path;
            g_status = msg;
            // Ghi log ra console cho de debug
            NSLog(@"[PixelStrike3D-Dump] %@ | path=%s", [NSString stringWithUTF8String:msg.c_str()], path.c_str());
            (void)ok;
            g_isDumping = false;
        }
    });
}
