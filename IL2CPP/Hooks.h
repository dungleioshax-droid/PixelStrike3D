#import "Loggers.h"
#include "ext.h"
#include "../ESPConfig.h"
#include <chrono>

// IL2CPP Class Metadata Structure
struct Il2CppClassMetadata
{
    void* image; // 0x0
    void* gc_desc; // 0x8
    const char* name; // 0x10
    const char* namespaze; // 0x18
};

// IL2CPP Hook Functions - Only used functions
void *Type_GetType(monoString *instance) {
    try {
        const void* methodPtr = IL2Cpp::GetMethodOffset("mscorlib.dll", "System", "Type", "GetType", 1);
        if (!methodPtr) {
            //Logger::error("Type_GetType method offset is null");
            return nullptr;
        }
        return reinterpret_cast<void *(__fastcall *)(monoString *)>((uint64_t) methodPtr)(instance);
    } catch (...) {
        //Logger::error("Failed to get Type_GetType method offset");
        return nullptr;
    }
}

monoArray<void **>*Object_FindObjectsOfType(void *instance) {
    try {
        const void* methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Object", "FindObjectsOfType", 1);
        if (!methodPtr) {
            //Logger::error("Object_FindObjectsOfType method offset is null");
            return nullptr;
        }
        return reinterpret_cast<monoArray<void **>*(__fastcall *)(void *)>((uint64_t) methodPtr)(instance);
    } catch (...) {
        //Logger::error("Failed to get Object_FindObjectsOfType method offset");
        return nullptr;
    }
}

bool GameObject_get_activeInHierarchy(void *instance) {
    try {
        const void* methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "get_activeInHierarchy", 0);
        if (!methodPtr) {
            //Logger::error("GameObject_get_activeInHierarchy method offset is null");
            return false;
        }
        return reinterpret_cast<bool(__fastcall *)(void *)>((uint64_t) methodPtr)(instance);
    } catch (...) {
        //Logger::error("Failed to get GameObject_get_activeInHierarchy method offset");
        return false;
    }
}

void *Component_get_gameObject(void *component) {
    try {
        return reinterpret_cast<void *(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Component", "get_gameObject", 0))(component);
    } catch (...) {
        //Logger::error("Failed to get Component_get_gameObject method offset");
        return nullptr;
    }
}

void *Component_get_transform(void *instance) {
    try {
        return reinterpret_cast<void *(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Component", "get_transform", 0))(instance);
    } catch (...) {
        //Logger::error("Failed to get Component_get_transform method offset");
        return nullptr;
    }
}

void *GameObject_get_transform(void *instance) {
    try {
        return reinterpret_cast<void *(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "get_transform", 0))(instance);
    } catch (...) {
        //Logger::error("Failed to get GameObject_get_transform method offset");
        return nullptr;
    }
}

monoArray<void **>*GameObject_GetComponentsInternal(void *instance, void *type, bool useSearch, bool recursive, bool includeInactive, bool reverse, void *object) {
    try {
        return reinterpret_cast<monoArray<void **>*(__fastcall *)(void *, void *, bool, bool, bool, bool, void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "GetComponentsInternal", 6))(instance, type, useSearch, recursive, includeInactive, reverse, object);
    } catch (...) {
        //Logger::error("Failed to get GameObject_GetComponentsInternal method offset");
        return nullptr;
    }
}

Vector3 Transform_get_position(void *instance) {
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_position", 0))(instance);
    } catch (...) {
        //Logger::error("Failed to get Transform_get_position method offset");
        return Vector3();
    }
}

// --- Position setter (dung cho Teleport) ---
void Transform_set_position(void *instance, Vector3 position) {
    try {
        reinterpret_cast<void(__fastcall *)(void *, Vector3)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "set_position", 1))(instance, position);
    } catch (...) {
    }
}

// --- Rotation (dung cho Aimbot) ---
Quaternion Transform_get_rotation(void *instance) {
    try {
        return reinterpret_cast<Quaternion(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_rotation", 0))(instance);
    } catch (...) {
        return Quaternion::Identity();
    }
}

void Transform_set_rotation(void *instance, Quaternion rotation) {
    try {
        reinterpret_cast<void(__fastcall *)(void *, Quaternion)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "set_rotation", 1))(instance, rotation);
    } catch (...) {
    }
}

void* Transform_get_parent(void* transform) {
    try {
        return reinterpret_cast<void*(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_parent", 0))(transform);
    } catch (...) {
        //Logger::error("Failed to get Transform_get_parent method offset");
        return nullptr;
    }
}

int Transform_get_childCount(void* transform) {
    try {
        return reinterpret_cast<int(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_childCount", 0))(transform);
    } catch (...) {
        //Logger::error("Failed to get Transform_get_childCount method offset");
        return 0;
    }
}

Vector3 Transform_get_forward(void *instance) {
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_forward", 0))(instance);
    } catch (...) {
        return Vector3(0, 0, 1);
    }
}

Vector3 Transform_get_right(void *instance) {
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_right", 0))(instance);
    } catch (...) {
        return Vector3(1, 0, 0);
    }
}

Vector3 Transform_get_up(void *instance) {
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "get_up", 0))(instance);
    } catch (...) {
        return Vector3(0, 1, 0);
    }
}

void *Camera_get_main() {
    try {
        return reinterpret_cast<void *(__fastcall *)()>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "get_main", 0))();
    } catch (...) {
        //Logger::error("Failed to get Camera_get_main method offset");
        return nullptr;
    }
}

monoString *String_CreateString(const char *str) {
    try {
        return reinterpret_cast<monoString *(__fastcall *)(void *, const char *, int, int)>((uint64_t) IL2Cpp::GetMethodOffset("mscorlib.dll", "System", "String", "CreateString", 3))(NULL, str, 0, strlen(str));
    } catch (...) {
        //Logger::error("Failed to get String_CreateString method offset");
        return nullptr;
    }
}

Vector3 Camera_WorldToViewportPoint(void *camera, Vector3 position) {
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *, Vector3)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToViewportPoint", 1))(camera, position);
    } catch (...) {
        //Logger::error("Failed to get Camera_WorldToViewportPoint method offset");
        return Vector3();
    }
}

Vector3 Camera_WorldtoscreenPoint(void* camera, Vector3 position){
    try {
        return reinterpret_cast<Vector3(__fastcall *)(void *, Vector3)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Camera", "WorldToScreenPoint", 1))(camera, position);
    } catch (...) {
        //Logger::error("Failed to get Camera_WorldToScreenPoint method offset");
        return Vector3();
    }
}

monoArray<void**>* SkinnedMeshRenderer_get_bones(void* smr) {
    try {
        return reinterpret_cast<monoArray<void**>*(__fastcall *)(void *)>((uint64_t) IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "SkinnedMeshRenderer", "get_bones", 0))(smr);
    } catch (...) {
        //Logger::error("Failed to get SkinnedMeshRenderer_get_bones method offset");
        return nullptr;
    }
}

void* Transform_GetChild(void* transform, int index) {
    try {
        const void* methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "GetChild", 1);
        if (!methodPtr) return nullptr;
        return reinterpret_cast<void*(__fastcall *)(void *, int)>((uint64_t) methodPtr)(transform, index);
    } catch (...) {
        return nullptr;
    }
}

void* Transform_Find(void* transform, const char* name) {
    try {
        const void* methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Transform", "Find", 1);
        if (!methodPtr) return nullptr;
        monoString* ms = String_CreateString(name);
        if (!ms) return nullptr;
        return reinterpret_cast<void*(__fastcall *)(void *, monoString*)>((uint64_t) methodPtr)(transform, ms);
    } catch (...) {
        return nullptr;
    }
}

// Animator.GetBoneTransform(HumanBodyBones) - Animator nằm ở UnityEngine.AnimationModule.dll
void* Animator_GetBoneTransform(void* animator, int humanBoneId) {
    try {
        static const void* methodPtr = nullptr;
        static bool resolved = false;
        if (!resolved) {
            resolved = true;
            methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.AnimationModule.dll", "UnityEngine", "Animator", "GetBoneTransform", 1);
            if (!methodPtr) {
                // Fallback: thử CoreModule (một số bản Unity cũ)
                methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Animator", "GetBoneTransform", 1);
            }
        }
        if (!methodPtr) return nullptr;
        return reinterpret_cast<void*(__fastcall *)(void *, int)>((uint64_t) methodPtr)(animator, humanBoneId);
    } catch (...) {
        return nullptr;
    }
}

// Object.get_name for identifying transform bone names
inline monoString* Object_get_name(void* object) {
    if (!object) return nullptr;
    try {
        static const void* methodPtr = nullptr;
        if (!methodPtr) {
            methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "Object", "get_name", 0);
        }
        if (!methodPtr) return nullptr;
        return reinterpret_cast<monoString*(__fastcall *)(void*)>((uint64_t) methodPtr)(object);
    } catch (...) {
        return nullptr;
    }
}

inline std::string Transform_GetName(void* transform) {
    if (!transform) return "";
    @try {
        monoString* ms = Object_get_name(transform);
        if (ms) {
            char* c = ms->toCString();
            if (c) return std::string(c);
        }
    } @catch (...) {}
    return "";
}

inline bool IsIgnoredBoneName(const std::string& name) {
    if (name.empty()) return false;
    std::string s = name;
    std::transform(s.begin(), s.end(), s.begin(), ::tolower);
    if (s.find("gun") != std::string::npos) return true;
    if (s.find("weapon") != std::string::npos) return true;
    if (s.find("trail") != std::string::npos) return true;
    if (s.find("particle") != std::string::npos) return true;
    if (s.find("muzzle") != std::string::npos) return true;
    if (s.find("bullet") != std::string::npos) return true;
    if (s.find("sound") != std::string::npos) return true;
    if (s.find("audio") != std::string::npos) return true;
    if (s.find("cam") != std::string::npos) return true;
    if (s.find("flash") != std::string::npos) return true;
    if (s.find("mag") != std::string::npos) return true;
    if (s.find("attach") != std::string::npos) return true;
    if (s.find("collider") != std::string::npos) return true;
    if (s.find("emoji") != std::string::npos) return true;
    if (s.find("canvas") != std::string::npos) return true;
    if (s.find("nametag") != std::string::npos) return true;
    return false;
}

// Gọi Physics.Linecast an toàn qua il2cpp_runtime_invoke
// Ưu tiên overload 4 tham số để truyền layerMask + QueryTriggerInteraction.Ignore (bỏ qua trigger)
inline bool Physics_SafeLinecast(Vector3 start, Vector3 end, int layerMask, int queryTrigger) {
    @try {
        static void* m4 = nullptr;
        static void* m2 = nullptr;
        static bool tried = false;
        if (!tried) {
            tried = true;
            const char* dlls[2] = {"UnityEngine.PhysicsModule.dll", "UnityEngine.CoreModule.dll"};
            for (int i = 0; i < 2; i++) {
                void* img = IL2Cpp::GetImage(dlls[i]);
                if (!img) continue;
                if (!IL2Cpp::il2cpp_class_from_name || !IL2Cpp::il2cpp_class_get_method_from_name) break;
                void* klass = IL2Cpp::il2cpp_class_from_name(img, "UnityEngine", "Physics");
                if (!klass) continue;
                if (!m4) m4 = IL2Cpp::il2cpp_class_get_method_from_name(klass, "Linecast", 4);
                if (!m2) m2 = IL2Cpp::il2cpp_class_get_method_from_name(klass, "Linecast", 2);
            }
        }

        void* method = m4;
        bool use4 = (m4 != nullptr);
        if (!method) { method = m2; use4 = false; }
        if (!method) return false;

        // Đính kèm thread Metal vào IL2CPP domain trước khi invoke
        if (IL2Cpp::il2cpp_thread_current && IL2Cpp::il2cpp_domain_get && IL2Cpp::il2cpp_thread_attach) {
            if (!IL2Cpp::il2cpp_thread_current()) {
                void* domain = IL2Cpp::il2cpp_domain_get();
                if (domain) IL2Cpp::il2cpp_thread_attach(domain);
            }
        }

        void* args[4];
        int argc;
        if (use4) {
            args[0] = &start; args[1] = &end; args[2] = &layerMask; args[3] = &queryTrigger;
            argc = 4;
        } else {
            args[0] = &start; args[1] = &end;
            argc = 2;
        }

        void* exc = nullptr;
        if (IL2Cpp::il2cpp_runtime_invoke && IL2Cpp::il2cpp_object_unbox) {
            void* res = IL2Cpp::il2cpp_runtime_invoke(method, nullptr, args, &exc);
            if (res && !exc) {
                return *(bool*)IL2Cpp::il2cpp_object_unbox(res);
            }
        }
    } @catch (...) {}
    return false;
}

// VisCheck: quét tường cản, có cache + chống nhấp nháy màu
struct VisCheckCacheEntry {
    bool used = false;
    bool result = true;
    bool candidate = true;
    int candidateCount = 0;
    double lastCheck = 0.0;
};

inline VisCheckCacheEntry* VisCheckCache() {
    static VisCheckCacheEntry cache[64];
    return cache;
}

inline void VisCheckResetCache() {
    VisCheckCacheEntry* cache = VisCheckCache();
    for (int i = 0; i < 64; i++) {
        cache[i].used = false;
        cache[i].result = true;
        cache[i].candidate = true;
        cache[i].candidateCount = 0;
        cache[i].lastCheck = 0.0;
    }
}

inline bool VisCheckPlayer(Vector3 camPos, Vector3 headPos, Vector3 feetPos, Vector3 selfHeadPos, int slotId = -1) {
    @try {
        VisCheckCacheEntry* cache = VisCheckCache();

        auto nowSec = [&]() -> double {
            return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
        };

        // Định nghĩa 1 cache slot cho player này
        VisCheckCacheEntry* e = nullptr;
        if (slotId >= 0 && slotId < 64) {
            e = &cache[slotId];
            if (e->used && (nowSec() - e->lastCheck) < 0.05) return e->result;
        }

        Vector3 delta = headPos - camPos;
        float total = Vector3::Distance(camPos, headPos);
        if (total < 2.0f) {           // đứng sát / rất gần -> chắc chắn nhìn thấy
            if (e) { e->used = true; e->lastCheck = nowSec(); e->result = true; e->candidate = true; e->candidateCount = 0; }
            return true;
        }
        if (total > 300.0f) return true;

        Vector3 dir = delta / total;

        // BỎ QUA CHÍNH MÌNH: camera TPS nằm sau lưng nên tia luôn xuyên qua người chơi.
        // Bắt đầu raycast từ SAU thân mình + 0.8m để không tự chặn mình.
        float tSelf = Vector3::Dot(selfHeadPos - camPos, dir);
        float startT = tSelf + 0.8f;
        if (startT < 0.3f) startT = 0.3f;
        if (startT > total - 0.8f) startT = total - 0.8f;
        if (startT < 0.2f) {
            if (e) { e->used = true; e->lastCheck = nowSec(); e->result = true; e->candidate = true; e->candidateCount = 0; }
            return true;
        }
        Vector3 origin = camPos + (dir * startT);

        // layerMask -1 = Physics.AllLayers, QueryTriggerInteraction.Ignore = 1 (bỏ qua trigger)
        auto castTo = [&](const Vector3& target) -> bool {
            Vector3 d = target - origin;
            float len = Vector3::Distance(origin, target);
            if (len < 0.6f) return true;
            Vector3 u = d / len;
            // Dừng trước collider của chính mục tiêu 0.45m
            return !Physics_SafeLinecast(origin, target - (u * 0.45f), -1, 1);
        };

        Vector3 chestPos(feetPos.x, feetPos.y + 1.05f, feetPos.z);
        Vector3 bellyPos(feetPos.x, feetPos.y + 0.60f, feetPos.z);

        // Thấy bất kỳ tầm nào (đầu / ngực / bụng) là xanh -> rất nhạy, hết hiện trạng đỏ khi địch đứng thẳng trước mặt
        bool visible = castTo(headPos) || castTo(chestPos) || castTo(bellyPos);

        if (e) {
            e->used = true;
            e->lastCheck = nowSec();
            if (visible == e->result) {
                e->candidate = visible;
                e->candidateCount = 0;
            } else {
                // Xác nhận liên tiếp 2 lần mới đổi màu -> mượt, không nhấp nháy
                if (e->candidate == visible) {
                    e->candidateCount++;
                } else {
                    e->candidate = visible;
                    e->candidateCount = 1;
                }
                if (e->candidateCount >= 2) {
                    e->result = visible;
                    e->candidateCount = 0;
                }
            }
            return e->result;
        }
        return visible;
    } @catch (...) {
        return true;
    }
}

// World to Screen conversion functions
void WorldToScreen(void *camera, Vector3 position, Vector3 &screen, bool &checker) {
    if (!camera) return;
    screen = Camera_WorldToViewportPoint(camera, position);
    if (screen.z > 0) {
        screen.x *= kWidth; screen.y = kHeight - screen.y * kHeight;
    } else {
        screen.x = kWidth - screen.x * kWidth; screen.y *= kHeight;
    }
    checker = (screen.z > 0);
}

void WorldToScreenPoint(void* camera, Vector3 position, Vector3 &screen, bool &checker) {
    if (!camera) return;
    screen = Camera_WorldtoscreenPoint(camera, position);
    if (screen.z > 0) {
        screen.x = screen.x;
        screen.y = kHeight - screen.y;
    } else {
        screen.x = kWidth - screen.x;
        screen.y = screen.y;
    }
    checker = (screen.z > 0);
}

// Camera validation function
bool isCameraValid(void* camera) {
    if (!camera) return false;
    
    // Check if camera has valid transform
    void* transform = Component_get_transform(camera);
    if (!transform) return false;
    
    // Check if transform has valid position
    Vector3 pos = Transform_get_position(transform);
    if (pos.x == 0 && pos.y == 0 && pos.z == 0) return false;
    
    // Check if GameObject is active
    void* gameObject = Component_get_gameObject(camera);
    if (!gameObject) return false;
    if (!GameObject_get_activeInHierarchy(gameObject)) return false;
    
    return true;
}

// ============================================================================
// PixelStrike3D Helpers (Health Component)
// ============================================================================

// Check if Health instance belongs to local player
inline bool Health_get_isLocal(void* healthInstance) {
    if (!healthInstance) return false;
    try {
        static const void* methodPtr = nullptr;
        if (!methodPtr) {
            methodPtr = IL2Cpp::GetMethodOffset(PLAYER_ASSEMBLY_NAME, "", "Health", "get_isLocal", 0);
        }
        if (methodPtr) {
            return reinterpret_cast<bool(__fastcall *)(void *)>((uint64_t) methodPtr)(healthInstance);
        }
    } catch (...) {}
    // Fallback: check playerController field at offset 0x60
    @try {
        void* pc = *(void**)((uintptr_t)healthInstance + 0x60);
        return (pc != nullptr);
    } @catch (...) {
        return false;
    }
}

// Check if player is dead (field dead @ 0x2c or health <= 0)
inline bool Health_isDead(void* healthInstance) {
    if (!healthInstance) return true;
    @try {
        bool dead = *(bool*)((uintptr_t)healthInstance + 0x2c);
        float hp = *(float*)((uintptr_t)healthInstance + 0x20);
        return (dead || hp <= 0.0f);
    } @catch (...) {
        return false;
    }
}

// Get player team (field team @ 0x30)
inline int Health_getTeam(void* healthInstance) {
    if (!healthInstance) return -1;
    @try {
        return *(int32_t*)((uintptr_t)healthInstance + 0x30);
    } @catch (...) {
        return -1;
    }
}

// Get player current HP (field health @ 0x20)
inline float Health_getHealth(void* healthInstance) {
    if (!healthInstance) return 0.0f;
    @try {
        return *(float*)((uintptr_t)healthInstance + 0x20);
    } @catch (...) {
        return 0.0f;
    }
}

// Get player max HP (field maxHealth @ 0x28)
inline float Health_getMaxHealth(void* healthInstance) {
    if (!healthInstance) return 100.0f;
    @try {
        float maxH = *(float*)((uintptr_t)healthInstance + 0x28);
        return maxH > 0.0f ? maxH : 100.0f;
    } @catch (...) {
        return 100.0f;
    }
}

// Check if player is bot (field isBot @ 0xc0)
inline bool Health_isBot(void* healthInstance) {
    if (!healthInstance) return false;
    @try {
        return *(bool*)((uintptr_t)healthInstance + 0xc0);
    } @catch (...) {
        return false;
    }
}

// Get nametag transform (field nametag @ 0xa0) - gives top of head position
inline void* Health_getNametag(void* healthInstance) {
    if (!healthInstance) return nullptr;
    @try {
        return *(void**)((uintptr_t)healthInstance + 0xa0);
    } @catch (...) {
        return nullptr;
    }
}

// Get player name (field playerName @ 0xf8)
inline std::string Health_getPlayerName(void* healthInstance) {
    if (!healthInstance) return "Player";
    @try {
        monoString* ms = *(monoString**)((uintptr_t)healthInstance + 0xf8);
        if (ms) {
            char* cstr = ms->toCString();
            if (cstr && strlen(cstr) > 0) {
                return std::string(cstr);
            }
        }
    } @catch (...) {}
    if (Health_isBot(healthInstance)) return "Bot";
    return "Player";
}

// Lấy ClothingManager của player từ Health (chứa các slot head, gear, hands, boots)
inline void* Health_GetClothingManager(void* healthInstance) {
    if (!healthInstance) return nullptr;
    @try {
        void* netPlayer = *(void**)((uintptr_t)healthInstance + 0xd0);
        if (netPlayer) {
            void* pd = *(void**)((uintptr_t)netPlayer + 0x20);
            if (pd) {
                void* cm = *(void**)((uintptr_t)pd + 0x20);
                if (cm) return cm;
            }
        }
    } @catch (...) {}
    @try {
        void* go = Component_get_gameObject(healthInstance);
        if (go) {
            static void* cmType = nullptr;
            if (!cmType) {
                cmType = Type_GetType(String_CreateString("ClothingManager, Assembly-CSharp.dll"));
            }
            if (cmType) {
                static const void* method = nullptr;
                if (!method) {
                    method = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "GetComponentInChildren", 1);
                }
                if (method) {
                    void* cm = reinterpret_cast<void*(__fastcall *)(void*, void*)>((uint64_t)method)(go, cmType);
                    if (cm) return cm;
                }
            }
        }
    } @catch (...) {}
    return nullptr;
}

// Lấy ExtendedBodyBehavior của player (chứa các slot chi tiết từng khớp xương)
inline void* Health_GetExtendedBodyBehavior(void* healthInstance) {
    if (!healthInstance) return nullptr;
    @try {
        void* go = Component_get_gameObject(healthInstance);
        if (go) {
            static void* ebbType = nullptr;
            if (!ebbType) {
                ebbType = Type_GetType(String_CreateString("ExtendedBodyBehavior, Assembly-CSharp.dll"));
            }
            if (ebbType) {
                static const void* method = nullptr;
                if (!method) {
                    method = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "GetComponentInChildren", 1);
                }
                if (method) {
                    return reinterpret_cast<void*(__fastcall *)(void*, void*)>((uint64_t)method)(go, ebbType);
                }
            }
        }
    } @catch (...) {}
    return nullptr;
}

// Lấy SkinnedMeshRenderer của player từ Health
inline void* Health_GetSkinnedMeshRenderer(void* healthInstance) {
    if (!healthInstance) return nullptr;
    // 1. Direct chain: health -> netPlayer (0xd0) -> playerDisplay (0x20) -> clothingManager (0x20) -> skinSlot (0x58)
    @try {
        void* netPlayer = *(void**)((uintptr_t)healthInstance + 0xd0);
        if (netPlayer) {
            void* pd = *(void**)((uintptr_t)netPlayer + 0x20);
            if (pd) {
                void* cm = *(void**)((uintptr_t)pd + 0x20);
                if (cm) {
                    void* smr = *(void**)((uintptr_t)cm + 0x58);
                    if (smr) return smr;
                }
            }
        }
    } @catch (...) {}

    // 2. Component search: GameObject.GetComponentsInChildren(typeof(SkinnedMeshRenderer))
    @try {
        void* go = Component_get_gameObject(healthInstance);
        if (go) {
            static void* smrType = nullptr;
            if (!smrType) {
                smrType = Type_GetType(String_CreateString("UnityEngine.SkinnedMeshRenderer, UnityEngine.CoreModule.dll"));
            }
            if (smrType) {
                static const void* method = nullptr;
                if (!method) {
                    method = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "GetComponentsInChildren", 1);
                }
                if (method) {
                    monoArray<void**>* arr = reinterpret_cast<monoArray<void**>*(__fastcall *)(void*, void*)>((uint64_t)method)(go, smrType);
                    if (arr && arr->getLength() > 0) {
                        return arr->getPointer()[0];
                    }
                }
            }
        }
    } @catch (...) {}

    return nullptr;
}

// Lấy nhiều SkinnedMeshRenderer của player (có cache + tự invalidate khi player đổi)
// bones của SkinnedMeshRenderer là xương được Animator ghi transform mỗi khung hình -> luôn chuyển động
inline int Health_GetSkinnedMeshRenderers(void* healthInstance, void** out, int maxOut) {
    if (!healthInstance || !out || maxOut <= 0) return 0;
    @try {
        struct SmrCacheEntry { void* owner; Vector3 pos; double stamp; void* smr[8]; int count; };
        static SmrCacheEntry cache[24];
        static int rotate = 0;

        Vector3 curPos = Transform_get_position(Component_get_transform(healthInstance));
        double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();

        // Cache hợp lệ khi: cùng owner, người chơi không dịch quá xa, và còn trong hạn 1 giây
        // (làm mới định kỳ để bắt được mesh tay/ngắm mới sinh ra lúc cầm súng)
        for (int i = 0; i < 24; i++) {
            SmrCacheEntry& c = cache[i];
            if (c.owner == healthInstance && c.count > 0) {
                if (Vector3::Distance(c.pos, curPos) < 3.0f && (now - c.stamp) < 0.35) {
                    int k = c.count < maxOut ? c.count : maxOut;
                    for (int j = 0; j < k; j++) out[j] = c.smr[j];
                    return k;
                }
                c.owner = nullptr;
                c.count = 0;
            }
        }

        void* go = Component_get_gameObject(healthInstance);
        if (!go) return 0;

        static void* smrType = nullptr;
        if (!smrType) {
            smrType = Type_GetType(String_CreateString("UnityEngine.SkinnedMeshRenderer, UnityEngine.CoreModule.dll"));
        }
        if (!smrType) return 0;

        static const void* method = nullptr;
        if (!method) {
            method = IL2Cpp::GetMethodOffset("UnityEngine.CoreModule.dll", "UnityEngine", "GameObject", "GetComponentsInChildren", 1);
        }
        if (!method) return 0;

        monoArray<void**>* arr = reinterpret_cast<monoArray<void**>*(__fastcall *)(void*, void*)>((uint64_t)method)(go, smrType);
        if (!arr) return 0;

        SmrCacheEntry& c = cache[rotate];
        rotate = (rotate + 1) % 24;
        c.owner = healthInstance;
        c.pos = curPos;
        c.stamp = now;
        c.count = 0;
        int n = arr->getLength();
        for (int i = 0; i < n && c.count < 8; i++) {
            void* s = arr->getPointer()[i];
            if (s) c.smr[c.count++] = s;
        }
        int k = c.count < maxOut ? c.count : maxOut;
        for (int j = 0; j < k; j++) out[j] = c.smr[j];
        return k;
    } @catch (...) {}
    return 0;
}

// Animator.isHuman - kiểm tra Animator có dùng rig humanoid không
inline bool Animator_IsHuman(void* animator) {
    if (!animator) return false;
    try {
        static const void* methodPtr = nullptr;
        static bool resolved = false;
        if (!resolved) {
            resolved = true;
            methodPtr = IL2Cpp::GetMethodOffset("UnityEngine.AnimationModule.dll", "UnityEngine", "Animator", "get_isHuman", 0);
        }
        if (!methodPtr) return false;
        return reinterpret_cast<bool(__fastcall *)(void*)>((uint64_t) methodPtr)(animator);
    } catch (...) {
        return false;
    }
}

// Lấy Animator của player.
// Game có 3 Animator trên chuỗi: NetworkPlayer.anim(0x98), PlayerDisplay.anim(0x28), ClothingManager.anim(0x20)
// Chỉ Animator có isHuman == true mới lấy được xương bằng GetBoneTransform (xương animate thật)
inline void* Health_GetAnimator(void* healthInstance) {
    if (!healthInstance) return nullptr;
    try {
        void* netPlayer = *(void**)((uintptr_t)healthInstance + 0xd0);
        if (!netPlayer) return nullptr;

        void* pd = *(void**)((uintptr_t)netPlayer + 0x20);
        void* cm = pd ? *(void**)((uintptr_t)pd + 0x20) : nullptr;

        void* candidates[3];
        candidates[0] = *(void**)((uintptr_t)netPlayer + 0x98);
        candidates[1] = pd ? *(void**)((uintptr_t)pd + 0x28) : nullptr;
        candidates[2] = cm ? *(void**)((uintptr_t)cm + 0x20) : nullptr;

        // Ưu tiên Animator humanoid
        for (int i = 0; i < 3; i++) {
            if (candidates[i] && Animator_IsHuman(candidates[i])) return candidates[i];
        }
        // Không có humanoid nào -> trả về Animator đầu tiên khác null
        for (int i = 0; i < 3; i++) {
            if (candidates[i]) return candidates[i];
        }
    } catch (...) {}
    return nullptr;
}

// Lấy world position của 1 bone qua Animator. Return false nếu bone null.
inline bool Health_GetBonePos(void* animator, int boneId, Vector3 &outPos) {
    if (!animator) return false;
    try {
        void* boneT = Animator_GetBoneTransform(animator, boneId);
        if (!boneT) return false;
        Vector3 p = Transform_get_position(boneT);
        if (p.x == 0 && p.y == 0 && p.z == 0) return false;
        outPos = p;
        return true;
    } catch (...) {
        return false;
    }
}

// Legacy aliases
inline bool Hunter_get_IsLocallyControlled(void* hunterInstance) {
    return Health_get_isLocal(hunterInstance);
}

inline int IPlayerInGame_get_Kind(void* playerInstance) {
    return Health_getTeam(playerInstance);
}
