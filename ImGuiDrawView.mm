#import "Esp/ImGuiDrawView.h"
#import "Init/IL2CPPInit.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include "IMGUI/imgui.h"
#include "IMGUI/imgui_internal.h"
#include "IMGUI/imgui_impl_metal.h"
#include "IMGUI/zzz.h"
#include "IMGUI/Il2cpp.h"
#include <vector>
#include <string>
#define oxorany(x) x
#include "IL2CPP/Vector3.h"
#include "IL2CPP/Vector2.h"
#include "IL2CPP/Vector4.h"
#include "IL2CPP/Quaternion.h"
#include "IL2CPP/Matrix4x4.h"
#include "IL2CPP/Monostring.h"
#include "ESPConfig.h"
#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#include "IL2CPP/Hooks.h"
#include "IL2CPP/Dumper.h"
#import <Foundation/Foundation.h>
#import <os/log.h>
#import "pthread.h"
#include <math.h>
#include <deque>
#include <vector>
#include <fstream>
#include <ctime>
#import <dlfcn.h>
#import <substrate.h>
#include <map>
#include <set>
#include <algorithm>
#include <string>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <unistd.h>
#include <string.h>
#include <float.h>
ImFont* verdana_smol;
#define kScale [UIScreen mainScreen].scale
static void* selectedCamera = nullptr;
static bool espInitialized = false;
static bool esp_line = false;
static bool esp_corners = true;
static bool esp_skeleton = true;
static bool esp_health = true;
static bool esp_name = true;
static bool esp_distance_enabled = true;
static bool esp_vischeck = true;
static int esp_line_position = 1;
static bool esp_draw_all_players = false;

// --- AIMBOT (Aim Assist) ---
static bool aim_enabled = false;
static float aim_fov = 140.0f;        // ban kinh FOV (pixel) tinh tu tam man hinh
static float aim_smooth = 0.45f;      // 0 = snap tuc thi, cang lon cang muot
static int aim_target_bone = 0;       // 0 = Dau (head), 1 = Nguc (chest)
static bool aim_visible_only = true;  // chi ngam dich khong bi tuong can
static bool aim_ignore_teammates = true;
static float aim_max_distance = 200.0f;
static float aim_y_offset = 0.0f;     // tinh chinh do cao diem ngam (m), am = thap xuong
static bool  aim_debug = true;             // hien FOV + thong tin muc tieu de kiem tra
static bool  silent_aim_enabled = false;   // be huong dan luc ban (khong xoay camera)
static bool  no_spread_enabled = false;    // xoa do tan dan + do giat

// --- PREDICTION (ban don theo van toc dich) ---
static bool  pred_enabled = false;
static float pred_bullet_speed = 500.0f;   // m/s - cang cao cang it doan truoc
static float pred_smooth = 0.45f;          // lam muot van toc (0 = nhay, 0.95 = rat muot)
static float pred_max_speed = 40.0f;       // bo qua van toc bat thuong (teleport/hoi sinh)
std::string decodeBase64(const char* encoded) {
    NSString *encodedStr = [NSString stringWithUTF8String:encoded];
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:encodedStr options:0];
    if (decodedData) {
        NSString *decodedStr = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        return std::string([decodedStr UTF8String]);
    }
    return std::string(encoded);
}
bool isInBattle() {
    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return false;
    monoArray<void**>* playerList = Object_FindObjectsOfType(playerRootType);
    if (!playerList) return false;
    for (int i = 0; i < playerList->getLength(); i++) {
        void* object = playerList->getPointer()[i];
        if (!object) continue;
        void* gameObject = Component_get_gameObject(object);
        if (!gameObject || !GameObject_get_activeInHierarchy(gameObject)) continue;
        void* transform = Component_get_transform(object);
        if (!transform) continue;
        Vector3 position = Transform_get_position(transform);
        if (position.x == 0 && position.y == 0 && position.z == 0) continue;
        return true;
    }
    return false;
}
void* getMainCamera() {
    static int lastCheckFrame = 0;
    static int frameCount = 0;
    frameCount++;
    if (!selectedCamera || frameCount - lastCheckFrame > 30) {
        lastCheckFrame = frameCount;
        void* mainCam = Camera_get_main();
        if (mainCam) {
            void* transform = Component_get_transform(mainCam);
            if (transform) {
                Vector3 pos = Transform_get_position(transform);
                if (pos.x != 0 || pos.y != 0 || pos.z != 0) {
                    selectedCamera = mainCam;
                    return selectedCamera;
                }
            }
        }
        void* CameraType = Type_GetType(String_CreateString("UnityEngine.Camera, UnityEngine.CoreModule.dll"));
        if (CameraType) {
            monoArray<void**>* allCameras = Object_FindObjectsOfType(CameraType);
            if (allCameras) {
                void* bestCamera = nullptr;
                for (int i = 0; i < allCameras->getLength(); i++) {
                    void* cam = allCameras->getPointer()[i];
                    if (!cam) continue;
                    void* gameObject = Component_get_gameObject(cam);
                    if (!gameObject) continue;
                    if (!GameObject_get_activeInHierarchy(gameObject)) continue;
                    void* transform = Component_get_transform(cam);
                    if (!transform) continue;
                    Vector3 pos = Transform_get_position(transform);
                    if (pos.x == 0 && pos.y == 0 && pos.z == 0) continue;
                    if (!bestCamera) {
                        bestCamera = cam;
                    }
                }
                if (bestCamera) {
                    selectedCamera = bestCamera;
    return selectedCamera;
                }
            }
        }
    }
    return selectedCamera;
}
int getLocalPlayerType() {
    static int cachedTeam = -1;
    static int lastCheckFrame = 0;
    static int frameCounter = 0;
    frameCounter++;
    if (cachedTeam >= 0 && frameCounter - lastCheckFrame < 60) {
        return cachedTeam;
    }
    lastCheckFrame = frameCounter;
    cachedTeam = -1;

    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (playerRootType) {
        monoArray<void**>* list = Object_FindObjectsOfType(playerRootType);
        if (list) {
            for (int i = 0; i < list->getLength(); i++) {
                void* obj = list->getPointer()[i];
                if (!obj) continue;
                if (Health_get_isLocal(obj)) {
                    cachedTeam = Health_getTeam(obj);
                    return cachedTeam;
                }
            }
        }
    }
    return cachedTeam;
}
void updateESPVariables(bool line, bool distance, int linePos, bool corners, bool skeleton, bool health, bool name, bool vischeck) {
    esp_line = line;
    esp_distance_enabled = distance;
    esp_line_position = linePos;
    esp_corners = corners;
    esp_skeleton = skeleton;
    esp_health = health;
    esp_name = name;
    esp_vischeck = vischeck;
}
struct PlayerData {
    void* object;
    void* gameObject;
    void* transform;
    Vector3 position;
    Vector3 headPosition;
    Vector3 w2sPosition;
    Vector3 w2sHead;
    bool isVisible;
    float distance;
    bool isLocalPlayer;
    bool isTeammate;
    bool isVisibleToCam;
    int team;
    float health;
    float maxHealth;
    std::string name;

    PlayerData() : object(nullptr), gameObject(nullptr), transform(nullptr), 
                   isVisible(false), distance(0.0f), isLocalPlayer(false),
                   isTeammate(false), isVisibleToCam(false), team(-1),
                   health(100.0f), maxHealth(100.0f), name("Player") {}
};

// ============================================================================
// ESP Skeleton - PixelStrike3D (Accurate Articulated Skeleton Engine)
// 1. ClothingManager actual animated limb transforms (Hands, Feet, Gear, Hat)
// 2. SkinnedMeshRenderer bone hierarchy with strict distance & name filtering
// 3. Transform Hierarchy Crawler with anti-excess filtering (no weapon/particle lines)
// 4. Proportional Voxel Biped Fallback
// ============================================================================
inline void DrawSkeletonBone(ImDrawList* draw_list, void* camera,
                             const Vector3 &a, const Vector3 &b,
                             ImU32 color, float thickness, float maxDist = 2.0f) {
    @try {
        float d = Vector3::Distance(a, b);
        if (d < 0.01f || d > maxDist) return;
        Vector3 sa, sb; bool va = false, vb = false;
        WorldToScreen(camera, a, sa, va);
        WorldToScreen(camera, b, sb, vb);
        if (!va || !vb) return;
        if ((sa.x < -100 || sa.x > kWidth + 100 || sa.y < -100 || sa.y > kHeight + 100) &&
            (sb.x < -100 || sb.x > kWidth + 100 || sb.y < -100 || sb.y > kHeight + 100)) return;
        draw_list->AddLine(ImVec2(sa.x, sa.y), ImVec2(sb.x, sb.y), color, thickness);
    } @catch (...) {}
}

// --- Nhận diện xương người theo TÊN bone (SkinnedMeshRenderer.bones là xương animate thật) ---
// Rig that cua PixelStrike3D (doc tu file log that, 1 SkinnedMeshRenderer ten "body", 24 bone):
//   0 floor  1 body_lower  2 body_0  3 head  4 Eye_Right  5 Eye_Left
//   6 l_arm  7 l_arm_lower  8 r_arm  9 r_arm_lower
//   10 r_leg  11 r_leg_lower  12 Feet_Right  13 l_leg  14 l_leg_lower  15 Feet_Left
//   16..23 IK-*  <- muc tieu IK, KHONG phai xuong than, bo qua
// Rig nay KHONG co xuong Shoulder / Hand, chi co 2 khop moi canh tay.
enum BoneSlot {
    BS_Hips = 0,      // floor
    BS_Spine,         // body_lower
    BS_Chest,         // body_0
    BS_Head,          // head
    BS_LArm,          // l_arm       (vai)
    BS_LForeArm,      // l_arm_lower (co tay)
    BS_RArm,          // r_arm
    BS_RForeArm,      // r_arm_lower
    BS_LThigh,        // l_leg
    BS_LKnee,         // l_leg_lower
    BS_LFoot,         // Feet_Left
    BS_RThigh,        // r_leg
    BS_RKnee,         // r_leg_lower
    BS_RFoot,         // Feet_Right
    BS_COUNT
};

// Map CHINH XAC theo ten bone that cua game (khong doan bang chuoi con)
inline int DetectHumanBone(const std::string& n) {
    if (n.empty()) return -1;
    // Bo qua muc tieu IK va mat
    if (n.find("ik") != std::string::npos) return -1;
    if (n.find("eye") != std::string::npos) return -1;

    if (n == "floor")            return BS_Hips;
    if (n == "body_lower")       return BS_Spine;
    if (n == "body_0")           return BS_Chest;
    if (n == "head")             return BS_Head;
    if (n == "l_arm")            return BS_LArm;
    if (n == "l_arm_lower")      return BS_LForeArm;
    if (n == "r_arm")            return BS_RArm;
    if (n == "r_arm_lower")      return BS_RForeArm;
    if (n == "l_leg")            return BS_LThigh;
    if (n == "l_leg_lower")      return BS_LKnee;
    if (n == "feet_left")        return BS_LFoot;
    if (n == "r_leg")            return BS_RThigh;
    if (n == "r_leg_lower")      return BS_RKnee;
    if (n == "feet_right")       return BS_RFoot;
    return -1;
}

// Chuan hoa ten: bo prefix "mixamorig:", chuyen chu thuong, giu nguyen dau '_'
inline std::string BoneKey(const std::string& raw) {
    std::string n = raw;
    size_t colon = n.find(':');
    if (colon != std::string::npos) n = n.substr(colon + 1);
    std::transform(n.begin(), n.end(), n.begin(), ::tolower);
    return n;
}

// Doc xuong that tu SkinnedMeshRenderer "body"
inline int ReadSkeletonBones(void* healthObj, Vector3* slots, bool* got) {
    for (int i = 0; i < BS_COUNT; i++) { got[i] = false; slots[i] = Vector3(); }

    void* smrs[8];
    int smrCount = Health_GetSkinnedMeshRenderers(healthObj, smrs, 8);
    if (smrCount <= 0) return 0;

    for (int i = 0; i < smrCount; i++) {
        monoArray<void**>* bones = SkinnedMeshRenderer_get_bones(smrs[i]);
        if (!bones) continue;
        int cnt = bones->getLength();
        for (int b = 0; b < cnt; b++) {
            void* t = bones->getPointer()[b];
            if (!t) continue;
            int slot = DetectHumanBone(BoneKey(Transform_GetName(t)));
            if (slot < 0 || got[slot]) continue;
            Vector3 p = Transform_get_position(t);
            if (p.x == 0 && p.y == 0 && p.z == 0) continue;
            slots[slot] = p;
            got[slot] = true;
        }
    }

    int found = 0;
    for (int i = 0; i < BS_COUNT; i++) if (got[i]) found++;
    return found;
}

inline int DrawPlayerSkeleton(ImDrawList* draw_list, void* camera, void* healthObj,
                             void* playerTransform, const Vector3& cameraPos, const Vector3& feetPos, const Vector3& headPos,
                             ImU32 color, float thickness) {
    if (!healthObj || !camera) return 0;

    @try {
        Vector3 s[BS_COUNT];
        bool got[BS_COUNT];
        int found = ReadSkeletonBones(healthObj, s, got);

        // Xuong bat buoc: hang, nguc, dui, chan. Khong co -> bo qua player nay
        if (!got[BS_Hips] || !got[BS_Chest] || !got[BS_LThigh] || !got[BS_RThigh]) return 0;

        Vector3 hips = s[BS_Hips];
        Vector3 chest = got[BS_Chest] ? s[BS_Chest] : s[BS_Spine];
        Vector3 head = got[BS_Head] ? s[BS_Head] : (chest + Vector3(0.0f, 0.60f, 0.0f));

        // Do dai tham chieu = khoang cach that giua hang va dau
        float bodyLen = Vector3::Distance(hips, head);
        if (bodyLen < 0.5f || bodyLen > 4.0f) bodyLen = 1.0f;

        // Chỉ sua khi khop bi TRUNG nhau (do dai ~0). KHONG rut ngan khop that.
        // Vi du: r_leg -> Feet_Right that la 1.18m, nen bo qua han muc 0.75m cu.
        auto keepLength = [&](Vector3 from, Vector3 to, float minLen) -> Vector3 {
            Vector3 d = to - from;
            float len = Vector3::Distance(from, to);
            if (len < minLen) {
                if (d.sqrMagnitude() < 0.0001f) d = Vector3(0.0f, -1.0f, 0.0f);
                to = from + (d.normalized() * minLen);
            } else if (len > bodyLen * 3.0f) {
                if (d.sqrMagnitude() < 0.0001f) d = Vector3(0.0f, -1.0f, 0.0f);
                to = from + (d.normalized() * (bodyLen * 1.5f));
            }
            return to;
        };

        // Co: khong co xuong neck -> noi thang giua nguc va dau
        Vector3 neck = chest + ((head - chest) * 0.55f);

        // Tay: chi 2 khop (vai -> canh tay -> co tay)
        Vector3 lArm = got[BS_LArm] ? s[BS_LArm] : (chest - Vector3(0.0f, 0.0f, 0.0f));
        Vector3 rArm = got[BS_RArm] ? s[BS_RArm] : lArm;
        if (!got[BS_LArm] && !got[BS_RArm]) {
            Vector3 side(1.0f, 0.0f, 0.0f);
            if (playerTransform) {
                Vector3 rt = Transform_get_right(playerTransform);
                Vector3 flat(rt.x, 0.0f, rt.z);
                if (flat.sqrMagnitude() > 0.0001f) side = flat.normalized();
            }
            lArm = chest - (side * (bodyLen * 0.28f));
            rArm = chest + (side * (bodyLen * 0.28f));
        }
        float armMin = bodyLen * 0.10f;
        lArm = keepLength(chest, lArm, armMin);
        rArm = keepLength(chest, rArm, armMin);
        Vector3 lFore = got[BS_LForeArm] ? keepLength(lArm, s[BS_LForeArm], armMin) : (lArm - Vector3(0.0f, armMin, 0.0f));
        Vector3 rFore = got[BS_RForeArm] ? keepLength(rArm, s[BS_RForeArm], armMin) : (rArm - Vector3(0.0f, armMin, 0.0f));

        // Chan: 3 khop (hoi -> dui -> goi -> ban chan)
        float legMin = bodyLen * 0.12f;
        Vector3 lThigh = got[BS_LThigh] ? s[BS_LThigh] : (hips - Vector3(0.0f, 0.0f, 0.0f));
        Vector3 rThigh = got[BS_RThigh] ? s[BS_RThigh] : lThigh;
        lThigh = keepLength(hips, lThigh, legMin);
        rThigh = keepLength(hips, rThigh, legMin);
        Vector3 lKnee = got[BS_LKnee] ? keepLength(lThigh, s[BS_LKnee], legMin) : (lThigh - Vector3(0.0f, legMin, 0.0f));
        Vector3 rKnee = got[BS_RKnee] ? keepLength(rThigh, s[BS_RKnee], legMin) : (rThigh - Vector3(0.0f, legMin, 0.0f));
        Vector3 lFoot = got[BS_LFoot] ? keepLength(lKnee, s[BS_LFoot], legMin) : (lKnee - Vector3(0.0f, legMin, 0.0f));
        Vector3 rFoot = got[BS_RFoot] ? keepLength(rKnee, s[BS_RFoot], legMin) : (rKnee - Vector3(0.0f, legMin, 0.0f));

        int lines = 0;

        // Than
        DrawSkeletonBone(draw_list, camera, hips, chest, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, chest, neck, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, neck, head, color, thickness); lines++;

        // Tay
        DrawSkeletonBone(draw_list, camera, chest, lArm, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, lArm, lFore, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, chest, rArm, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, rArm, rFore, color, thickness); lines++;

        // Chan
        DrawSkeletonBone(draw_list, camera, hips, lThigh, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, lThigh, lKnee, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, lKnee, lFoot, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, hips, rThigh, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, rThigh, rKnee, color, thickness); lines++;
        DrawSkeletonBone(draw_list, camera, rKnee, rFoot, color, thickness); lines++;

        return lines;
    } @catch (...) {}

    return 0;
}

// ==================== LOG XUONG THAT ====================
static const char* kHumanBoneNames[23] = {
    "Hips", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot", "Spine", "Chest", "UpperChest", "Neck", "Head",
    "LeftShoulder", "RightShoulder", "LeftUpperArm", "RightUpperArm",
    "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand",
    "LeftToes", "RightToes", "LastBone"
};

inline std::string BoneDump_Vec(Vector3 v) {
    char b[96];
    snprintf(b, sizeof(b), "(%8.3f, %8.3f, %8.3f)", v.x, v.y, v.z);
    return std::string(b);
}

inline std::string DumpPlayerBonesNow(int maxPlayers = 3) {
    @autoreleasepool {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docs = [paths firstObject];
        if (!docs) return std::string("FAIL: khong lay duoc Documents path");
        std::string path = std::string([docs UTF8String]) + "/PixelStrike3D_bones.txt";

        std::ofstream out(path, std::ios::out | std::ios::trunc);
        if (!out.is_open()) return "FAIL: khong mo duoc file " + path;

        time_t now = time(nullptr);
        char tb[64] = {0};
        strftime(tb, sizeof(tb), "%Y-%m-%d %H:%M:%S", localtime(&now));
        out << "===== PIXELSTRIKE3D BONE LOG =====\nTime: " << tb << "\nPath: " << path << "\n\n";

        std::string typeName = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
        void* healthType = Type_GetType(String_CreateString(typeName.c_str()));
        if (!healthType) { out << "FAIL: khong tim thay class Health\n"; return path; }

        monoArray<void**>* list = Object_FindObjectsOfType(healthType);
        if (!list) { out << "FAIL: khong lay duoc danh sach player\n"; return path; }

        int count = list->getLength();
        int written = 0;
        for (int i = 0; i < count && written < maxPlayers; i++) {
            void* health = list->getPointer()[i];
            if (!health) continue;
            if (Health_get_isLocal(health)) continue;
            if (Health_isDead(health)) continue;
            void* go = Component_get_gameObject(health);
            void* tf = Component_get_transform(health);
            if (!go || !tf) continue;

            out << "############################################\n";
            out << "PLAYER[" << written << "] ptr=" << health << "\n";
            out << "  Name          = " << Health_getPlayerName(health) << "\n";
            out << "  Root position = " << BoneDump_Vec(Transform_get_position(tf)) << "\n";
            void* ntag = Health_getNametag(health);
            if (ntag) out << "  Nametag pos   = " << BoneDump_Vec(Transform_get_position(ntag)) << "\n";

            void* netPlayer = *(void**)((uintptr_t)health + 0xd0);
            void* pd = netPlayer ? *(void**)((uintptr_t)netPlayer + 0x20) : nullptr;
            void* cm = pd ? *(void**)((uintptr_t)pd + 0x20) : nullptr;
            out << "  NetworkPlayer = " << netPlayer << "  PlayerDisplay = " << pd << "  ClothingManager = " << cm << "\n";
            void* an0 = netPlayer ? *(void**)((uintptr_t)netPlayer + 0x98) : nullptr;
            out << "  Animator      = " << an0 << "  isHuman=" << (an0 && Animator_IsHuman(an0) ? "YES" : "no") << "\n\n";

            out << "---- SMR BONES ----\n";
            void* smrs[8];
            int smrCount = Health_GetSkinnedMeshRenderers(health, smrs, 8);
            out << "  so SkinnedMeshRenderer = " << smrCount << "\n";
            for (int m = 0; m < smrCount; m++) {
                out << "  [SMR " << m << "] name='" << Transform_GetName(smrs[m]) << "'\n";
                monoArray<void**>* bones = SkinnedMeshRenderer_get_bones(smrs[m]);
                if (!bones) { out << "      bones=NULL\n"; continue; }
                int bc = bones->getLength();
                out << "      so bone = " << bc << "\n";
                for (int b = 0; b < bc; b++) {
                    void* bt = bones->getPointer()[b];
                    if (!bt) { out << "      [" << b << "] NULL\n"; continue; }
                    out << "      [" << b << "] '" << Transform_GetName(bt) << "'"
                        << " world=" << BoneDump_Vec(Transform_get_position(bt)) << "\n";
                }
            }
            out << "\n";
            written++;
        }
        out << "===== HET: " << written << " player =====\n";
        out.close();
        return path;
    }
}


// Ket qua quet muc tieu cua frame hien tai (dung cho aim + debug overlay)
static bool        g_aimFound = false;
static bool        g_aimCameraOk = false;
static bool        g_aimUsingPlayerCamera = false;
static Vector3     g_aimTargetScreen;
static float       g_aimTargetDistance = 0.0f;
static std::string g_aimTargetName;
static void*       g_aimTargetObject = nullptr;
static void*       g_aimTargetRoot = nullptr;      // Transform goc cua dich (dung cho teleport)
static Vector3     g_aimTargetWorldPoint;          // diem ngam cuoi cung (da tinh prediction)

// --- Silent aim state ---
static bool       silentAimHooked = false;
static bool       g_silentWantRotValid = false;
static Quaternion g_silentWantRot;
static void*      g_silentAimTransform = nullptr;
static bool       g_silentBusy = false;

// ============================================================================
// LAY TRANSFORM CAMERA THAT CUA NGUOI CHOI
// Duong di (offset tu PixelStrike3D_dump.txt):
//   Health.playerController        @ 0x60   (class Health)
//   PlayerController.cameraTransform @ 0xe0 (class PlayerController)
// ============================================================================
static void* getLocalCameraTransform() {
    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return nullptr;
    monoArray<void**>* list = Object_FindObjectsOfType(playerRootType);
    if (!list) return nullptr;
    for (int i = 0; i < list->getLength(); i++) {
        void* obj = list->getPointer()[i];
        if (!obj) continue;
        if (!Health_get_isLocal(obj)) continue;
        void* pc = *(void**)((uintptr_t)obj + 0x60);   // Health.playerController
        if (!pc) continue;
        void* camT = *(void**)((uintptr_t)pc + 0xe0);  // PlayerController.cameraTransform
        if (camT) return camT;
    }
    return nullptr;
}

// ============================================================================
// SILENT AIM - hook WeaponController.fire()
// Truoc khi ban: xoay cameraTransform ve muc tieu -> goi ham goc -> tra lai goc ngay.
// Nguoi choi khong thay camera quay, nhung dan bay ve phia dich.
// ============================================================================
static void applyNoSpread();   // dinh nghia ben duoi (can cho hook_fire)

typedef void (*FireFn)(void*);
static FireFn orig_fire = nullptr;

static void hook_fire(void* self) {
    if (!silent_aim_enabled || !g_silentWantRotValid || g_silentBusy) {
        if (orig_fire) orig_fire(self);
        return;
    }
    void* aimT = g_silentAimTransform;
    if (!aimT) {
        if (orig_fire) orig_fire(self);
        return;
    }

    g_silentBusy = true;
    @try {
        Quaternion saved = Transform_get_rotation(aimT);
        Transform_set_rotation(aimT, g_silentWantRot);   // be huong ngam
        if (no_spread_enabled) applyNoSpread();          // xoa tan dan ngay truoc khi ban
        if (orig_fire) orig_fire(self);                  // game raycast theo huong nay
        Transform_set_rotation(aimT, saved);             // tra lai ngay -> "silent"
    } @catch (...) {
        if (orig_fire) orig_fire(self);
    }
    g_silentBusy = false;
}

// ============================================================================
// NO SPREAD - xoa do tan dan (bullet spread) + do giat (recoil)
// Offset tu PixelStrike3D_dump.txt - class NewWeapon [Assembly-CSharp.dll]
//   0x11c currBulletSpread   | 0x124 baseBulletSpread | 0x128 bulletSpreadModifier
//   0x12c maxBulletSpread    | 0x130 movementModifier
//   0xd8  recoil             | 0xf4  maxRecoil        | 0xf8  hipRecoil
// Duong di: Health.weaponController @ 0x58 -> WeaponController.currentWeapon @ 0xd0
// ============================================================================
static void* getLocalWeaponController() {
    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return nullptr;
    monoArray<void**>* list = Object_FindObjectsOfType(playerRootType);
    if (!list) return nullptr;
    for (int i = 0; i < list->getLength(); i++) {
        void* obj = list->getPointer()[i];
        if (!obj) continue;
        if (!Health_get_isLocal(obj)) continue;
        void* wc = *(void**)((uintptr_t)obj + 0x58);   // Health.weaponController
        if (wc) return wc;
        void* pc = *(void**)((uintptr_t)obj + 0x60);   // Health.playerController
        if (pc) {
            wc = *(void**)((uintptr_t)pc + 0x38);      // PlayerController.weaponController
            if (wc) return wc;
        }
        break;
    }
    return nullptr;
}

static void applyNoSpread() {
    void* wc = getLocalWeaponController();
    if (!wc) return;
    void* nw = *(void**)((uintptr_t)wc + 0xd0);   // WeaponController.currentWeapon
    if (!nw) return;

    *(float*)((uintptr_t)nw + 0x124) = 0.0f;  // baseBulletSpread
    *(float*)((uintptr_t)nw + 0x128) = 0.0f;  // bulletSpreadModifier
    *(float*)((uintptr_t)nw + 0x12c) = 0.0f;  // maxBulletSpread
    *(float*)((uintptr_t)nw + 0x11c) = 0.0f;  // currBulletSpread
    *(float*)((uintptr_t)nw + 0x130) = 0.0f;  // movementModifier
    *(float*)((uintptr_t)nw + 0xd8)  = 0.0f;  // recoil
    *(float*)((uintptr_t)nw + 0xf4)  = 0.0f;  // maxRecoil
    *(float*)((uintptr_t)nw + 0xf8)  = 0.0f;  // hipRecoil
}

static void installSilentAimHook() {
    if (silentAimHooked) return;
    static int cooldown = 0;
    if (cooldown > 0) { cooldown--; return; }
    cooldown = 120;   // thu lai moi 120 frame neu chua tim thay

    const void* fn = IL2Cpp::GetMethodOffset("Assembly-CSharp.dll", "", "WeaponController", "fire", 0);
    if (!fn) return;

    // KHONG gan orig_fire = fn truoc: neu MSHookFunction khong tra ve trampoline
    // thi hook se goi lai chinh no -> de quy vo han.
    FireFn trampoline = nullptr;
    MSHookFunction((void*)fn, (void*)hook_fire, (void**)&trampoline);
    orig_fire = trampoline;
    silentAimHooked = (orig_fire != nullptr);
}

// ============================================================================
// SPEED HACK - hook PlayerController.move(Vector3 movement)
// Nhan vector di chuyen len N lan -> chay nhanh/cham tuy slider.
// Cach nay an toan hon ghi field speed: game dung ObscuredFloat (CodeStage
// Anti-Cheat) cho realBaseSpeed/realOrigSpeed nen ghi float thuong se bi ghi de.
// Chi nhan truc X/Z de KHONG anh huong trong luc roi/roi tu do.
// ============================================================================
static bool  speed_hack_enabled = false;
static float speed_mult = 1.5f;        // 1.0 = binh thuong, <1 = cham, >1 = nhanh
static bool  speedHackHooked = false;

typedef void (*MoveFn)(void*, Vector3);
static MoveFn orig_move = nullptr;

static void hook_move(void* self, Vector3 movement) {
    if (speed_hack_enabled && speed_mult > 0.05f) {
        movement.x *= speed_mult;
        movement.z *= speed_mult;
    }
    if (orig_move) orig_move(self, movement);
}

static void installSpeedHackHook() {
    if (speedHackHooked) return;
    static int cooldown = 0;
    if (cooldown > 0) { cooldown--; return; }
    cooldown = 120;

    const void* fn = IL2Cpp::GetMethodOffset("Assembly-CSharp.dll", "", "PlayerController", "move", 1);
    if (!fn) return;

    MoveFn trampoline = nullptr;
    MSHookFunction((void*)fn, (void*)hook_move, (void**)&trampoline);
    orig_move = trampoline;
    speedHackHooked = (orig_move != nullptr);
}

static double nowSeconds();   // dinh nghia o phan PREDICTION ben duoi

// ============================================================================
// TELEPORT - dich chuyen toi dich gan nhat roi tu dong ban
// Duong di: Health.isLocal -> Component.get_transform -> Transform.set_position
// ============================================================================
// --- UNLIMITED AMMO ---
static bool inf_ammo_enabled = false;

// --- FAST BULLET ---
static bool  fast_bullet_enabled = false;
static float fast_bullet_speed = 2000.0f;   // toc do duong dan / luc ban

// --- FLY ---
static bool   fly_enabled = false;
static float  fly_speed = 2.5f;    // m/s, 0 = treo tai cho, am = ha xuong
static double fly_lastTime = 0.0;

static bool   tp_enabled = false;
static float  tp_y_offset = 0.0f;      // cao do dich len so voi chan dich (m)
static float  tp_interval = 1.0f;      // giay giua 2 lan teleport
static double tp_lastTime = 0.0;

static bool   tp_pendingFire = false;  // cho 1 vai frame cho vat ly on dinh roi moi ban
static int    tp_fireDelay = 0;

// Muc tieu teleport chon RIENG: chi theo khoang cach 3D,
// KHONG phu thuoc FOV / VisCheck / on-screen -> xuyen tuong van hoat dong.
static bool        g_tpFound = false;
static void*       g_tpTargetRoot = nullptr;
static Vector3     g_tpTargetHead;
static float       g_tpTargetDistance = 0.0f;
static std::string g_tpTargetName;

// Health cua nguoi choi local (co cache)
static void* getLocalPlayerHealth() {
    static void* cached = nullptr;
    static int frames = 0;
    frames++;
    if (cached && (frames % 60) != 0) {
        void* go = Component_get_gameObject(cached);
        if (go && GameObject_get_activeInHierarchy(go)) return cached;
        cached = nullptr;
    }

    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return cached;
    monoArray<void**>* list = Object_FindObjectsOfType(playerRootType);
    if (!list) return cached;
    for (int i = 0; i < list->getLength(); i++) {
        void* obj = list->getPointer()[i];
        if (!obj) continue;
        if (!Health_get_isLocal(obj)) continue;
        cached = obj;
        return cached;
    }
    return cached;
}

// Transform goc cua nguoi choi local
static void* getLocalPlayerTransform() {
    void* h = getLocalPlayerHealth();
    if (!h) return nullptr;
    return Component_get_transform(h);
}

// PlayerController cua nguoi choi local: Health.playerController @ 0x60
static void* getLocalPlayerController() {
    void* h = getLocalPlayerHealth();
    if (!h) return nullptr;
    return *(void**)((uintptr_t)h + 0x60);
}

// Goi truc tiep WeaponController.fire() (di qua hook_fire neu silent aim dang bat)
static void callWeaponFire(void* wc) {
    static FireFn fn = nullptr;
    if (!fn) fn = (FireFn)IL2Cpp::GetMethodOffset("Assembly-CSharp.dll", "", "WeaponController", "fire", 0);
    if (fn) fn(wc);
}

// Chon dich GAN NHAT theo khoang cach 3D trong the gioi (bo qua tuong/FOV/man hinh)
static void pickTeleportTarget() {
    g_tpFound = false;
    g_tpTargetRoot = nullptr;
    g_tpTargetName.clear();

    void* localT = getLocalPlayerTransform();
    if (!localT) return;
    Vector3 selfPos = Transform_get_position(localT);

    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return;
    monoArray<void**>* list = Object_FindObjectsOfType(playerRootType);
    if (!list) return;

    int localTeam = getLocalPlayerType();
    float bestDist = 0.0f;

    for (int i = 0; i < list->getLength(); i++) {
        void* object = list->getPointer()[i];
        if (!object) continue;
        if (Health_get_isLocal(object)) continue;
        if (Health_isDead(object)) continue;

        void* gameObject = Component_get_gameObject(object);
        if (!gameObject || !GameObject_get_activeInHierarchy(gameObject)) continue;

        void* transform = Component_get_transform(object);
        if (!transform) continue;

        Vector3 position = Transform_get_position(transform);
        if (position.x == 0 && position.y == 0 && position.z == 0) continue;

        if (aim_ignore_teammates) {
            int team = Health_getTeam(object);
            if (localTeam != -1 && team != -1 && team == localTeam) continue;
        }

        float d = Vector3::Distance(selfPos, position);
        if (g_tpFound && d >= bestDist) continue;

        // Diem dau: nametag nam TREN dau -> ha xuong 0.30m
        Vector3 headPos = Vector3(position.x, position.y + 1.55f, position.z);
        void* nametag = Health_getNametag(object);
        if (nametag) {
            Vector3 nPos = Transform_get_position(nametag);
            if ((nPos.x != 0 || nPos.y != 0 || nPos.z != 0) && nPos.y > position.y) {
                headPos = Vector3(nPos.x, nPos.y - 0.30f, nPos.z);
            }
        }

        bestDist = d;
        g_tpFound = true;
        g_tpTargetRoot = transform;
        g_tpTargetHead = headPos;
        g_tpTargetDistance = d;
        g_tpTargetName = Health_getPlayerName(object);
    }
}

static void doTeleport() {
    if (!tp_enabled) return;
    if (!g_tpFound || !g_tpTargetRoot) return;

    double now = nowSeconds();
    if (now - tp_lastTime < (double)tp_interval) return;
    tp_lastTime = now;

    void* localT = getLocalPlayerTransform();
    if (!localT) return;

    Vector3 ePos = Transform_get_position(g_tpTargetRoot);
    Vector3 dest = Vector3(ePos.x, ePos.y + tp_y_offset, ePos.z);
    Transform_set_position(localT, dest);

    tp_pendingFire = true;
    tp_fireDelay = 2;   // doi 2 frame cho CharacterController cap nhat vi tri
}

// Goi moi frame: sau khi teleport xong thi ngam roi ban
static void updateTeleportFire() {
    if (!tp_pendingFire) return;
    if (tp_fireDelay > 0) { tp_fireDelay--; return; }
    tp_pendingFire = false;

    // Ngam bang camera transform hien tai (vi tri da doi sau teleport)
    void* camT = getLocalCameraTransform();
    if (camT && g_tpFound) {
        Vector3 cp = Transform_get_position(camT);
        Vector3 dir = g_tpTargetHead - cp;
        if (dir.sqrMagnitude() > 0.0001f) {
            Transform_set_rotation(camT, Quaternion::LookRotation(dir, Vector3(0, 1, 0)));
        }
    }

    void* wc = getLocalWeaponController();
    if (wc) callWeaponFire(wc);
}

// ============================================================================
// UNLIMITED AMMO
// Offset (dump): WeaponController.unlimitedAmmo @ 0x135, bottomlessMagazine @ 0x136
//                WeaponController.currentWeapon @ 0xd0
//                NewWeapon.magazineCapacity @ 0xa4, magazineAmmo @ 0xa8,
//                          reserveAmmo @ 0xac
// ============================================================================
static void applyInfiniteAmmo() {
    void* wc = getLocalWeaponController();
    if (!wc) return;

    *(bool*)((uintptr_t)wc + 0x135) = true;   // unlimitedAmmo
    *(bool*)((uintptr_t)wc + 0x136) = true;   // bottomlessMagazine

    void* nw = *(void**)((uintptr_t)wc + 0xd0);   // currentWeapon
    if (!nw) return;

    int cap = *(int*)((uintptr_t)nw + 0xa4);      // magazineCapacity
    if (cap <= 0) cap = 30;
    *(int*)((uintptr_t)nw + 0xa8) = cap;          // magazineAmmo -> luon day
    *(int*)((uintptr_t)nw + 0xac) = 999;          // reserveAmmo
}

// ============================================================================
// FAST BULLET
// Offset (dump): BulletTracerController.bulletSpeed @ 0x38
//                NewWeapon.forwardForce @ 0x1a0 (luc ban cua sung phong)
// ============================================================================
static void applyFastBullet() {
    // Toc do duong dan (moi vien dan)
    void* type = Type_GetType(String_CreateString("BulletTracerController, Assembly-CSharp.dll"));
    if (type) {
        monoArray<void**>* list = Object_FindObjectsOfType(type);
        if (list && list->getLength() > 0) {
            void* bt = list->getPointer()[0];
            if (bt) *(float*)((uintptr_t)bt + 0x38) = fast_bullet_speed;
        }
    }

    // Luc bay cua đạn nổ / súng phóng
    void* wc = getLocalWeaponController();
    if (!wc) return;
    void* nw = *(void**)((uintptr_t)wc + 0xd0);
    if (!nw) return;
    *(float*)((uintptr_t)nw + 0x1a0) = fast_bullet_speed;   // forwardForce
}

// ============================================================================
// FLY
// Offset (dump): Health.playerController @ 0x60 -> PlayerController
//                PlayerController.falling @ 0x101, verticalSpeed @ 0xac
// Huy trong luc roi nang/ha do cao bang Transform.set_position.
// ============================================================================
static void applyFly() {
    if (!fly_enabled) return;

    void* pc = getLocalPlayerController();
    if (pc) {
        *(bool*)((uintptr_t)pc + 0x101) = false;   // falling = false -> khong roi
        *(float*)((uintptr_t)pc + 0xac) = 0.0f;    // verticalSpeed = 0
    }

    if (fabsf(fly_speed) < 0.01f) return;   // 0 = treo tai cho

    void* localT = getLocalPlayerTransform();
    if (!localT) return;

    double now = nowSeconds();
    float dt = (float)(now - fly_lastTime);
    fly_lastTime = now;
    if (dt <= 0.0f || dt > 0.2f) dt = 0.016f;

    Vector3 p = Transform_get_position(localT);
    p.y += fly_speed * dt;
    Transform_set_position(localT, p);
}

// ============================================================================
// PREDICTION - uoc luong van toc dich de ban don (chay/nhay/di chuyen)
// Van toc duoc lam muot bang EMA de marker khong giat khi bone animate.
// ============================================================================
struct PredTrack {
    Vector3 lastPos;
    Vector3 velocity;
    double  lastTime = 0.0;
};
static std::map<void*, PredTrack> g_predTracks;

static double nowSeconds() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

static void trackVelocity(void* key, const Vector3& pos) {
    if (!key) return;
    double now = nowSeconds();

    auto it = g_predTracks.find(key);
    if (it == g_predTracks.end()) {
        PredTrack t;
        t.lastPos = pos;
        t.lastTime = now;
        g_predTracks[key] = t;
        return;
    }

    PredTrack& t = it->second;
    float dt = (float)(now - t.lastTime);
    if (dt < 0.0005f || dt > 0.5f) {   // frame dau / khung hinh tre -> chi cap nhat moc
        t.lastPos = pos;
        t.lastTime = now;
        return;
    }

    Vector3 inst = (pos - t.lastPos) / dt;
    if (inst.magnitude() > pred_max_speed) {   // teleport / hoi sinh -> bo qua
        t.lastPos = pos;
        t.lastTime = now;
        return;
    }

    float k = 1.0f - pred_smooth;
    if (k < 0.05f) k = 0.05f;
    if (k > 1.0f) k = 1.0f;
    t.velocity = t.velocity * (1.0f - k) + inst * k;
    t.lastPos = pos;
    t.lastTime = now;
}

static void pruneVelocityTracks() {
    double now = nowSeconds();
    for (auto it = g_predTracks.begin(); it != g_predTracks.end(); ) {
        if (now - it->second.lastTime > 2.0) it = g_predTracks.erase(it);
        else ++it;
    }
}

// ============================================================================
// AIMBOT (Manual) - tu xoay transform camera ve phia muc tieu gan tam ngam nhat
// ============================================================================
static void updateAimbot() {
    g_aimFound = false;
    g_aimCameraOk = false;
    g_silentWantRotValid = false;
    g_aimTargetRoot = nullptr;
    g_aimTargetName.clear();

    if (!aim_enabled && !aim_debug && !silent_aim_enabled && !tp_enabled) return;

    pruneVelocityTracks();

    void* camera = getMainCamera();
    if (!isCameraValid(camera)) return;
    g_aimCameraOk = true;
    Vector3 camPos = Transform_get_position(Component_get_transform(camera));

    // Uu tien transform camera THAT cua nguoi choi (PlayerController.cameraTransform)
    // thay vi Camera.main - day moi la truc ngam cua game.
    void* camTransform = getLocalCameraTransform();
    g_aimUsingPlayerCamera = (camTransform != nullptr);
    if (!camTransform) camTransform = Component_get_transform(camera);
    if (!camTransform) return;

    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return;
    monoArray<void**>* playerList = Object_FindObjectsOfType(playerRootType);
    if (!playerList) return;

    int playerCount = playerList->getLength();
    if (playerCount <= 0) return;

    int localTeam = getLocalPlayerType();
    Vector3 localSelfHead = camPos;
    for (int i = 0; i < playerCount; i++) {
        void* obj = playerList->getPointer()[i];
        if (!obj) continue;
        if (Health_get_isLocal(obj)) {
            void* selfT = Component_get_transform(obj);
            if (selfT) {
                Vector3 sp = Transform_get_position(selfT);
                localSelfHead = Vector3(sp.x, sp.y + 1.5f, sp.z);
            }
            break;
        }
    }

    const float cx = kWidth * 0.5f;
    const float cy = kHeight * 0.5f;

    float bestScreenDist = aim_fov;
    Vector3 bestWorld;
    bool found = false;

    for (int i = 0; i < playerCount; i++) {
        void* object = playerList->getPointer()[i];
        if (!object) continue;
        if (Health_get_isLocal(object)) continue;
        if (Health_isDead(object)) continue;

        void* gameObject = Component_get_gameObject(object);
        if (!gameObject || !GameObject_get_activeInHierarchy(gameObject)) continue;

        void* transform = Component_get_transform(object);
        if (!transform) continue;

        Vector3 position = Transform_get_position(transform);
        if (position.x == 0 && position.y == 0 && position.z == 0) continue;

        if (aim_ignore_teammates) {
            int team = Health_getTeam(object);
            if (localTeam != -1 && team != -1 && team == localTeam) continue;
        }

        // Theo doi van toc de ban don (dung vi tri goc, khong dung bone -> do nhieu)
        trackVelocity(object, position);

        float distance = Vector3::Distance(camPos, position);
        if (distance > aim_max_distance) continue;

        // Lay XUONG DAU that tu SkinnedMeshRenderer.
        // Luu y: nametag nam TREN dau nen KHONG duoc dung lam diem ngam (aim se bi cao).
        Vector3 boneSlots[BS_COUNT];
        bool boneGot[BS_COUNT];
        ReadSkeletonBones(object, boneSlots, boneGot);

        Vector3 headPos;
        if (boneGot[BS_Head]) {
            headPos = boneSlots[BS_Head];
        } else {
            // Fallback 1: uoc luong tu chan (nhan vat ~1.8m)
            headPos = Vector3(position.x, position.y + 1.55f, position.z);
            // Fallback 2: co nametag thi ha xuong cho ve dung dau
            void* nametag = Health_getNametag(object);
            if (nametag) {
                Vector3 nPos = Transform_get_position(nametag);
                if ((nPos.x != 0 || nPos.y != 0 || nPos.z != 0) && nPos.y > position.y) {
                    headPos = Vector3(nPos.x, nPos.y - 0.30f, nPos.z);
                }
            }
        }

        Vector3 chestPos = boneGot[BS_Chest]
            ? boneSlots[BS_Chest]
            : Vector3(position.x, position.y + 1.05f, position.z);

        Vector3 aimPoint = (aim_target_bone == 0) ? headPos : chestPos;
        aimPoint.y += aim_y_offset;   // tinh chinh them neu can

        if (aim_visible_only && !VisCheckPlayer(camPos, headPos, position, localSelfHead, i)) continue;

        Vector3 screen; bool onScreen = false;
        WorldToScreen(camera, aimPoint, screen, onScreen);
        if (!onScreen) continue;

        float dx = screen.x - cx;
        float dy = screen.y - cy;
        float screenDist = sqrtf(dx * dx + dy * dy);
        if (screenDist < bestScreenDist) {
            bestScreenDist = screenDist;
            bestWorld = aimPoint;
            g_aimTargetScreen = screen;
            g_aimTargetDistance = distance;
            g_aimTargetName = Health_getPlayerName(object);
            g_aimTargetObject = object;
            g_aimTargetRoot = transform;
            found = true;
        }
    }

    g_aimFound = found;
    if (!found) return;

    // PREDICTION: ban don ve phia truoc theo van toc dich
    //   thoi gian dan bay = khoang cach / toc do dan gia dinh
    if (pred_enabled) {
        auto it = g_predTracks.find(g_aimTargetObject);
        if (it != g_predTracks.end()) {
            float speed = (pred_bullet_speed < 50.0f) ? 50.0f : pred_bullet_speed;
            float timeToHit = g_aimTargetDistance / speed;
            bestWorld = bestWorld + it->second.velocity * timeToHit;

            // Cap nhat lai marker debug theo diem da doan truoc
            Vector3 scr; bool vis = false;
            WorldToScreen(camera, bestWorld, scr, vis);
            if (vis) g_aimTargetScreen = scr;
        }
    }

    g_aimTargetWorldPoint = bestWorld;

    Vector3 dir = bestWorld - camPos;
    if (dir.sqrMagnitude() < 0.0001f) return;

    Quaternion want = Quaternion::LookRotation(dir, Vector3(0, 1, 0));

    // Silent aim dung chung ket qua nay (chi luu lai, khong xoay camera)
    g_silentWantRot = want;
    g_silentWantRotValid = true;
    g_silentAimTransform = camTransform;

    if (!aim_enabled) return;   // chi bat silent aim -> khong keo camera man hinh

    float s = aim_smooth;
    if (s < 0.0f) s = 0.0f;
    if (s > 0.95f) s = 0.95f;

    if (s <= 0.001f) {
        Transform_set_rotation(camTransform, want);
    } else {
        Quaternion cur = Transform_get_rotation(camTransform);
        Transform_set_rotation(camTransform, Quaternion::Slerp(cur, want, 1.0f - s));
    }
}

// ============================================================================
// AIM DEBUG OVERLAY - hien vong FOV + muc tieu dang nham de biet aim co chay
// ============================================================================
static void drawAimDebugOverlay(ImDrawList* draw_list) {
    const float cx = kWidth * 0.5f;
    const float cy = kHeight * 0.5f;

    // Vong FOV quanh tam ngam
    draw_list->AddCircle(ImVec2(cx, cy), aim_fov, IM_COL32(0, 220, 255, 150), 72, 1.5f);

    // Tam ngam
    draw_list->AddLine(ImVec2(cx - 10, cy), ImVec2(cx + 10, cy), IM_COL32(255, 255, 255, 200), 1.0f);
    draw_list->AddLine(ImVec2(cx, cy - 10), ImVec2(cx, cy + 10), IM_COL32(255, 255, 255, 200), 1.0f);

    if (g_aimFound) {
        ImVec2 tp(g_aimTargetScreen.x, g_aimTargetScreen.y);
        draw_list->AddLine(ImVec2(cx, cy), tp, IM_COL32(255, 60, 60, 200), 1.5f);
        draw_list->AddCircle(tp, 10.0f, IM_COL32(255, 60, 60, 235), 20, 2.0f);
        draw_list->AddCircleFilled(tp, 3.0f, IM_COL32(255, 60, 60, 255));
    }

    std::string status = std::string("AIM ") + (aim_enabled ? "ON" : "OFF")
        + " | cam=" + (g_aimCameraOk ? "ok" : "NONE")
        + (g_aimUsingPlayerCamera ? " (player)" : " (main)")
        + " | silent=" + (silent_aim_enabled ? (silentAimHooked ? "hooked" : "no-hook") : "off")
        + " | pred=" + (pred_enabled ? (std::to_string((int)pred_bullet_speed) + " m/s") : std::string("off"))
        + " | target=" + (g_aimFound ? g_aimTargetName : std::string("none"))
        + " " + std::to_string((int)g_aimTargetDistance) + "m";
    draw_list->AddText(ImVec2(8, kHeight - 26), IM_COL32(255, 255, 0, 255), status.c_str());
}

int drawPlayerRootESP(ImDrawList* draw_list) {
    try {
        if (!isInBattle()) {
            return 0;
        }
    void* camera = getMainCamera();
    if (!isCameraValid(camera)) {
        return 0;
    }
    Vector3 cameraPosition = Transform_get_position(Component_get_transform(camera));
    bool shouldDrawESP = (esp_line || esp_distance_enabled || esp_corners || esp_skeleton || esp_health || esp_name);
    if (!shouldDrawESP) return 0;

    std::string typeString = std::string(PLAYER_CLASS_NAME) + ", " + std::string(PLAYER_ASSEMBLY_NAME);
    void* playerRootType = Type_GetType(String_CreateString(typeString.c_str()));
    if (!playerRootType) return 0;

    monoArray<void**>* playerList = Object_FindObjectsOfType(playerRootType);
    if (!playerList) return 0;

    int playerCount = playerList->getLength();
    if (playerCount <= 0) return 0;

    // Số lượng player đổi -> xóa cache VisCheck để không dùng nhầm kết quả của người khác
    static int lastPlayerCount = -1;
    if (lastPlayerCount != playerCount) {
        lastPlayerCount = playerCount;
        VisCheckResetCache();
    }

    // Tìm team + vị trí của local player
    int localTeam = -1;
    Vector3 localSelfHead = cameraPosition;
    for (int i = 0; i < playerCount; i++) {
        void* obj = playerList->getPointer()[i];
        if (!obj) continue;
        if (Health_get_isLocal(obj)) {
            localTeam = Health_getTeam(obj);
            void* selfT = Component_get_transform(obj);
            if (selfT) {
                Vector3 sp = Transform_get_position(selfT);
                // Điểm "đầu" của chính mình để bỏ qua collider người chơi khi raycast
                localSelfHead = Vector3(sp.x, sp.y + 1.5f, sp.z);
            }
            break;
        }
    }

    std::vector<PlayerData> validPlayers;
    validPlayers.reserve(playerCount);

    for (int i = 0; i < playerCount; i++) {
        void* object = playerList->getPointer()[i];
        if (!object) continue;

        // Bỏ qua local player
        if (Health_get_isLocal(object)) continue;

        // Bỏ qua người chơi đã chết
        if (Health_isDead(object)) continue;

        void* gameObject = Component_get_gameObject(object);
        if (!gameObject || !GameObject_get_activeInHierarchy(gameObject)) continue;

        void* transform = Component_get_transform(object);
        if (!transform) continue;

        Vector3 position = Transform_get_position(transform);
        if (position.x == 0 && position.y == 0 && position.z == 0) continue;

        int team = Health_getTeam(object);
        bool isTeammate = (localTeam != -1 && team != -1 && team == localTeam);

        // Nếu tắt "Draw All Players", chỉ vẽ địch (bỏ qua đồng đội)
        if (!esp_draw_all_players && isTeammate) continue;

        PlayerData playerData;
        playerData.object = object;
        playerData.gameObject = gameObject;
        playerData.transform = transform;
        playerData.position = position;
        playerData.team = team;
        playerData.isTeammate = isTeammate;
        playerData.health = Health_getHealth(object);
        playerData.maxHealth = Health_getMaxHealth(object);
        playerData.name = Health_getPlayerName(object);

        void* nametag = Health_getNametag(object);
        if (nametag) {
            Vector3 nPos = Transform_get_position(nametag);
            if (nPos.x != 0 || nPos.y != 0 || nPos.z != 0) {
                playerData.headPosition = nPos;
            } else {
                playerData.headPosition = Vector3(position.x, position.y + 1.8f, position.z);
            }
        } else {
            playerData.headPosition = Vector3(position.x, position.y + 1.8f, position.z);
        }

        playerData.distance = Vector3::Distance(cameraPosition, playerData.position);
        if (playerData.distance > ESP_MAX_DISTANCE) continue;

        // VisCheck: kiểm tra tường cản (áp dụng cho tất cả player hiển thị)
        if (esp_vischeck) {
            playerData.isVisibleToCam = VisCheckPlayer(cameraPosition, playerData.headPosition, playerData.position, localSelfHead, i);
        } else {
            playerData.isVisibleToCam = true;
        }

        WorldToScreen(camera, playerData.position, playerData.w2sPosition, playerData.isVisible);
        bool headVis = false;
        WorldToScreen(camera, playerData.headPosition, playerData.w2sHead, headVis);

        if (playerData.isVisible) {
            validPlayers.push_back(playerData);
        }
    }

    for (const auto& playerData : validPlayers) {
        // Màu ESP:
        // - Bật VisCheck (cả Địch và Draw All): Nhìn thấy = XANH LÁ (GREEN), Sau tường = ĐỎ (RED)
        // - Tắt VisCheck: Đồng đội = Xanh dương, Địch = Đỏ
        ImU32 playerColor;
        if (esp_vischeck) {
            playerColor = playerData.isVisibleToCam ? ESP_VIS_VISIBLE_COLOR : ESP_VIS_HIDDEN_COLOR;
        } else {
            if (playerData.isTeammate) {
                playerColor = IM_COL32(ESP_TEAM_COLOR_R, ESP_TEAM_COLOR_G, ESP_TEAM_COLOR_B, 255);
            } else {
                playerColor = IM_COL32(ESP_ENEMY_COLOR_R, ESP_ENEMY_COLOR_G, ESP_ENEMY_COLOR_B, 255);
            }
        }

        // ESP Line
        if (esp_line) {
            ImVec2 start, target;
            switch (esp_line_position) {
                case 0: start = ImVec2(kWidth * 0.5f, 5.0f); break;
                case 1: start = ImVec2(kWidth * 0.5f, kHeight * 0.5f); break;
                default: start = ImVec2(kWidth * 0.5f, kHeight - 5.0f); break;
            }
            target = ImVec2(playerData.w2sPosition.x, playerData.w2sPosition.y);
            draw_list->AddLine(start, target, playerColor, ESP_LINE_THICKNESS);
        }

        // 2. ESP Skeleton (dùng playerColor: xanh lá khi thấy, đỏ khi sau tường)
        if (esp_skeleton) {
            DrawPlayerSkeleton(draw_list, camera, playerData.object, playerData.transform, cameraPosition, playerData.position, playerData.headPosition, playerColor, ESP_SKELETON_THICKNESS);
        }

        // 3. Tính toán Bounding Box (cho Corner Box, Health Bar, Name, Distance)
        bool needBox = (esp_corners || esp_health || esp_name || esp_distance_enabled);
        if (needBox) {
            Vector3 c = playerData.position;
            float distance = playerData.distance;
            float baseHeight = 0.9f;
            float baseWidth = 0.4f;
            float baseDepth = 0.4f;
            Vector3 e = Vector3(baseWidth, baseHeight, baseDepth);

            float dynamicThickness = std::max(0.8f, 1.3f - (distance * 0.01f));
            float alpha = std::max(0.7f, 1.0f - (distance * 0.005f));
            ImU32 boxColor = (playerColor & 0x00FFFFFF) | (((int)(255 * alpha) & 0xFF) << 24);

            Vector3 corners3D[8] = {
                Vector3(c.x - e.x, c.y, c.z - e.z),
                Vector3(c.x + e.x, c.y, c.z - e.z),
                Vector3(c.x + e.x, c.y, c.z + e.z),
                Vector3(c.x - e.x, c.y, c.z + e.z),
                Vector3(c.x - e.x, c.y + e.y * 2.0f, c.z - e.z),
                Vector3(c.x + e.x, c.y + e.y * 2.0f, c.z - e.z),
                Vector3(c.x + e.x, c.y + e.y * 2.0f, c.z + e.z),
                Vector3(c.x - e.x, c.y + e.y * 2.0f, c.z + e.z)
            };

            ImVec2 pts[8];
            bool cornerVisible[8];
            int visibleCorners = 0;
            for (int k = 0; k < 8; k++) {
                Vector3 sp; bool vis;
                WorldToScreen(camera, corners3D[k], sp, vis);
                pts[k] = ImVec2(sp.x, sp.y);
                cornerVisible[k] = vis;
                if (vis) visibleCorners++;
            }

            if (visibleCorners >= 3) {
                float minX = FLT_MAX, maxX = -FLT_MAX, minY = FLT_MAX, maxY = -FLT_MAX;
                for (int k = 0; k < 8; k++) {
                    if (cornerVisible[k]) {
                        minX = std::min(minX, pts[k].x);
                        maxX = std::max(maxX, pts[k].x);
                        minY = std::min(minY, pts[k].y);
                        maxY = std::max(maxY, pts[k].y);
                    }
                }
                float boxHeight = maxY - minY;
                float boxWidth = maxX - minX;

                // CORNER BOX
                if (esp_corners) {
                    float cornerLength = std::max(8.0f, std::min(boxWidth, boxHeight) * 0.3f);
                    draw_list->AddLine(ImVec2(minX, minY), ImVec2(minX + cornerLength, minY), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(minX, minY), ImVec2(minX, minY + cornerLength), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(maxX, minY), ImVec2(maxX - cornerLength, minY), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(maxX, minY), ImVec2(maxX, minY + cornerLength), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(minX, maxY), ImVec2(minX + cornerLength, maxY), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(minX, maxY), ImVec2(minX, maxY - cornerLength), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(maxX, maxY), ImVec2(maxX - cornerLength, maxY), boxColor, dynamicThickness);
                    draw_list->AddLine(ImVec2(maxX, maxY), ImVec2(maxX, maxY - cornerLength), boxColor, dynamicThickness);
                }

                // ESP HEALTH (Thanh máu dọc bên trái kẻ địch style PC)
                if (esp_health) {
                    float barWidth = 3.5f;
                    float barMargin = 5.0f;
                    float barLeft = minX - barMargin - barWidth;
                    float barRight = barLeft + barWidth;

                    float maxHp = (playerData.maxHealth > 0.0f) ? playerData.maxHealth : 100.0f;
                    float curHp = std::max(0.0f, std::min(maxHp, playerData.health));
                    float hpPercent = curHp / maxHp;
                    float fillHeight = boxHeight * hpPercent;
                    float fillTop = maxY - fillHeight;
                    if (std::isnan(fillTop) || std::isinf(fillTop)) fillTop = maxY;

                    // Thanh máu xanh lá style PC (không nền, không viền đen)
                    ImU32 hpColor = IM_COL32(0, 255, 60, 255);
                    draw_list->AddRectFilled(ImVec2(barLeft, fillTop), ImVec2(barRight, maxY), hpColor);
                }

                // DƯỚI KẺ ĐỊCH: ESP NAME ở trên, ESP DISTANCE ở dưới (Bỏ nền đen, text nhỏ gọn, căn giữa)
                float centerX = (minX + maxX) * 0.5f;
                float currentBottomY = maxY + 2.0f;

                ImFont* curFont = ImGui::GetFont();
                float origFontScale = curFont ? curFont->Scale : 1.0f;
                if (curFont) curFont->Scale = origFontScale * 0.72f; // Thu nhỏ chữ lại theo yêu cầu

                // ESP NAME (nằm trên ESP Distance, ngay dưới chân kẻ địch)
                if (esp_name) {
                    std::string nameStr = playerData.name;
                    ImVec2 nameSize = ImGui::CalcTextSize(nameStr.c_str());
                    float nameX = centerX - nameSize.x * 0.5f;

                    // Đổ bóng 1px đen để đọc rõ trên mọi nền, không dùng khung đen
                    draw_list->AddText(ImVec2(nameX + 1, currentBottomY + 1), IM_COL32(0, 0, 0, 220), nameStr.c_str());
                    draw_list->AddText(ImVec2(nameX, currentBottomY), playerColor, nameStr.c_str());
                    currentBottomY += nameSize.y + 1.0f;
                }

                // ESP DISTANCE (nằm ngay dưới ESP Name)
                if (esp_distance_enabled) {
                    std::string distStr = std::to_string((int)playerData.distance) + "m";
                    ImVec2 distSize = ImGui::CalcTextSize(distStr.c_str());
                    float distX = centerX - distSize.x * 0.5f;

                    draw_list->AddText(ImVec2(distX + 1, currentBottomY + 1), IM_COL32(0, 0, 0, 220), distStr.c_str());
                    draw_list->AddText(ImVec2(distX, currentBottomY), IM_COL32(230, 230, 230, 255), distStr.c_str());
                }

                if (curFont) curFont->Scale = origFontScale; // Khôi phục cỡ chữ
            }
        }
    }
    } catch (...) {
        return 0;
    }
    return 0;
}
@interface ImGuiDrawView () <MTKViewDelegate>
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end
@implementation ImGuiDrawView
static bool show_s0 = false;
static bool MenDeal = true;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    if (!self.device) abort();
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowRounding = 0.0f;
    style.ChildRounding = 0.0f;
    style.FrameRounding = 0.0f;
    style.PopupRounding = 0.0f;
    style.ScrollbarRounding = 0.0f;
    style.GrabRounding = 0.0f;
    style.TabRounding = 0.0f;
    style.WindowBorderSize = 0.0f;
    style.ChildBorderSize = 0.0f;
    style.PopupBorderSize = 0.0f;
    style.FrameBorderSize = 0.0f;
    ImVec4* colors = style.Colors;
    colors[ImGuiCol_WindowBg] = ImVec4(0.08f, 0.05f, 0.12f, 0.94f); 
    colors[ImGuiCol_ChildBg] = ImVec4(0.06f, 0.04f, 0.10f, 0.94f);
    colors[ImGuiCol_PopupBg] = ImVec4(0.10f, 0.07f, 0.15f, 0.94f);
    colors[ImGuiCol_Border] = ImVec4(0.30f, 0.20f, 0.40f, 0.50f);
    colors[ImGuiCol_FrameBg] = ImVec4(0.15f, 0.10f, 0.20f, 1.0f);
    colors[ImGuiCol_FrameBgHovered] = ImVec4(0.20f, 0.15f, 0.30f, 1.0f);
    colors[ImGuiCol_FrameBgActive] = ImVec4(0.25f, 0.18f, 0.35f, 1.0f);
    colors[ImGuiCol_TitleBg] = ImVec4(0.12f, 0.08f, 0.18f, 1.0f);
    colors[ImGuiCol_TitleBgActive] = ImVec4(0.40f, 0.20f, 0.60f, 1.0f);
    colors[ImGuiCol_CheckMark] = ImVec4(0.60f, 0.30f, 0.90f, 1.0f);
    colors[ImGuiCol_Button] = ImVec4(0.40f, 0.20f, 0.60f, 0.60f);
    colors[ImGuiCol_ButtonHovered] = ImVec4(0.50f, 0.30f, 0.70f, 0.80f);
    colors[ImGuiCol_ButtonActive] = ImVec4(0.60f, 0.40f, 0.80f, 1.0f);
    colors[ImGuiCol_Header] = ImVec4(0.40f, 0.20f, 0.60f, 0.40f);
    colors[ImGuiCol_HeaderHovered] = ImVec4(0.50f, 0.30f, 0.70f, 0.60f);
    colors[ImGuiCol_HeaderActive] = ImVec4(0.60f, 0.40f, 0.80f, 0.80f);
    colors[ImGuiCol_Tab] = ImVec4(0.15f, 0.10f, 0.20f, 1.0f);
    colors[ImGuiCol_TabHovered] = ImVec4(0.50f, 0.30f, 0.70f, 0.60f);
    colors[ImGuiCol_TabActive] = ImVec4(0.40f, 0.20f, 0.60f, 1.0f);
    colors[ImGuiCol_Text] = ImVec4(0.95f, 0.90f, 1.0f, 1.0f);
    ImFont* font = io.Fonts->AddFontFromMemoryCompressedTTF((void*)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL, io.Fonts->GetGlyphRangesVietnamese());
    ImGui_ImplMetal_Init(_device);
    return self;
}
+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}
- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}
- (void)loadView
{
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    CGFloat h = [UIScreen mainScreen].bounds.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [IL2CPPInit startPrecheck];
    });
}
#pragma mark - Interaction
- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}
#pragma mark - Initialization Overlay
- (void)drawInitializationOverlay {
}
#pragma mark - MTKViewDelegate
- (void)drawInMTKView:(MTKView*)view
{
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    static bool esp_enabled = false;
        if (MenDeal == true) {
            [self.view setUserInteractionEnabled:YES];
        } else if (MenDeal == false) {
            [self.view setUserInteractionEnabled:NO];
        }
        MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
        if (renderPassDescriptor != nil)
        {
            id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder pushDebugGroup:@"ImGui Jane"];
            ImGui_ImplMetal_NewFrame(renderPassDescriptor);
            ImGui::NewFrame();
            [IL2CPPInit updateInitializationProgress];
            if ([IL2CPPInit isShowingInitOverlay] && ![IL2CPPInit isInitializationComplete]) {
            }
            ImFont* font = ImGui::GetFont();
            if (font && font->FontSize > 0) {
                font->Scale = 15.f / font->FontSize;
            }
            CGFloat x = (([UIScreen mainScreen].bounds.size.width) - 340) / 2;
            CGFloat y = (([UIScreen mainScreen].bounds.size.height) - 420) / 2;
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_FirstUseEver);
            ImGui::SetNextWindowSize(ImVec2(340, 420), ImGuiCond_FirstUseEver);
            if (MenDeal == true && [IL2CPPInit isInitializationComplete])
            {                
                std::string menuTitle = std::string("PixelStrike3D | Unity Dump + ESP");
                ImGui::Begin(menuTitle.c_str(), &MenDeal, ImGuiWindowFlags_NoResize);
                if (ImGui::BeginTabBar("MainTabBar"))
                {
                    if (ImGui::BeginTabItem("ESP"))
                    {
                        ImGui::Checkbox("ESP Enable", &esp_enabled);
                        ImGui::Separator();
                        if (esp_enabled) {
                            ImGui::Checkbox("ESP Line", &esp_line);
                            if (esp_line) {
                                const char* linePositions[] = {"Top", "Center", "Bottom"};
                                ImGui::Combo("Line Pos", &esp_line_position, linePositions, 3);
                            }
                            ImGui::Checkbox("Corner Box", &esp_corners);
                            ImGui::Checkbox("ESP Skeleton", &esp_skeleton);
                            ImGui::Checkbox("ESP Health (PC Style)", &esp_health);
                            ImGui::Checkbox("ESP Name", &esp_name);
                            ImGui::Checkbox("ESP Distance", &esp_distance_enabled);
                            ImGui::Checkbox("VisCheck (Green=See, Red=Wall)", &esp_vischeck);
                            ImGui::Checkbox("Draw All (Teammates & Enemies)", &esp_draw_all_players);
                            updateESPVariables(esp_line, esp_distance_enabled, esp_line_position, esp_corners, esp_skeleton, esp_health, esp_name, esp_vischeck);
                        }
                        ImGui::EndTabItem();
                    }
                    if (ImGui::BeginTabItem("Aim"))
                    {
                        ImGui::Checkbox("Aimbot", &aim_enabled);
                        ImGui::Checkbox("Silent Aim", &silent_aim_enabled);
                        ImGui::Checkbox("No Spread", &no_spread_enabled);
                        ImGui::Checkbox("Prediction", &pred_enabled);
                        if (pred_enabled) {
                            ImGui::SliderFloat("Bullet Speed", &pred_bullet_speed, 50.0f, 3000.0f, "%.0f");
                            ImGui::SliderFloat("Pred Smooth", &pred_smooth, 0.0f, 0.95f, "%.2f");
                        }
                        ImGui::Checkbox("Debug Overlay", &aim_debug);
                        ImGui::Separator();
                        ImGui::SliderFloat("FOV", &aim_fov, 10.0f, 500.0f, "%.0f");
                        ImGui::SliderFloat("Smooth", &aim_smooth, 0.0f, 0.95f, "%.2f");
                        const char* aimBones[] = {"Head", "Chest"};
                        ImGui::Combo("Target", &aim_target_bone, aimBones, 2);
                        ImGui::SliderFloat("Y Offset", &aim_y_offset, -0.6f, 0.6f, "%.2f");
                        ImGui::SliderFloat("Max Dist", &aim_max_distance, 10.0f, 300.0f, "%.0f");
                        ImGui::Checkbox("Visible Only", &aim_visible_only);
                        ImGui::Checkbox("Ignore Teammates", &aim_ignore_teammates);
                        ImGui::EndTabItem();
                    }
                    if (ImGui::BeginTabItem("Memory"))
                    {
                        ImGui::Checkbox("Speed Hack", &speed_hack_enabled);
                        ImGui::SliderFloat("Speed x", &speed_mult, 0.3f, 5.0f, "%.2f x");
                        if (speed_hack_enabled) {
                            if (!speedHackHooked) ImGui::TextColored(ImVec4(1,0.6f,0,1), "Dang tim hook...");
                            else ImGui::TextColored(ImVec4(0.4f,1,0.4f,1), "Speed Hack: ON");
                        }
                        ImGui::Separator();
                        ImGui::Checkbox("Teleport", &tp_enabled);
                        ImGui::SliderFloat("Y Offset", &tp_y_offset, -2.0f, 8.0f, "%.2f");
                        ImGui::SliderFloat("Interval", &tp_interval, 0.2f, 5.0f, "%.2f");
                        if (tp_enabled) {
                            if (!g_tpFound) ImGui::TextColored(ImVec4(1,0.6f,0,1), "Chua co dich");
                            else ImGui::TextColored(ImVec4(0.4f,1,0.4f,1), "Muc tieu: %s (%.0fm)", g_tpTargetName.c_str(), g_tpTargetDistance);
                        }
                        ImGui::Separator();
                        ImGui::Checkbox("Unlimited Ammo", &inf_ammo_enabled);
                        ImGui::Checkbox("Fast Bullet", &fast_bullet_enabled);
                        if (fast_bullet_enabled) {
                            ImGui::SliderFloat("Bullet Speed", &fast_bullet_speed, 100.0f, 10000.0f, "%.0f");
                        }
                        ImGui::Checkbox("Fly", &fly_enabled);
                        if (fly_enabled) {
                            ImGui::SliderFloat("Fly Speed", &fly_speed, -5.0f, 20.0f, "%.1f");
                        }
                        ImGui::EndTabItem();
                    }
                    if (ImGui::BeginTabItem("Info")) {
                        ImGui::Text("PixelStrike3D ESP + Dumper");
                        ImGui::Text("Unity IL2CPP Dump to Documents");
                        ImGui::EndTabItem();
                    }
                    }
                    ImGui::EndTabBar();
                ImGui::End();
            }
            ImDrawList* draw_list = ImGui::GetBackgroundDrawList();
            float topCenterX = kWidth * 0.5f;
            float topY = 35.0f; 
            std::string brandText = "PIXEL STRIKE 3D";
            ImVec2 brandTextSize = ImGui::CalcTextSize(brandText.c_str());
            float brandX = topCenterX - brandTextSize.x * 0.5f;
            float brandY = topY;
            for (int offsetX = -2; offsetX <= 2; offsetX++) {
                for (int offsetY = -2; offsetY <= 2; offsetY++) {
                    if (offsetX != 0 || offsetY != 0) {
                        draw_list->AddText(
                            ImVec2(brandX + offsetX, brandY + offsetY),
                            IM_COL32(0, 0, 0, 255),
                            brandText.c_str()
                        );
                    }
                }
            }
            draw_list->AddText(ImVec2(brandX, brandY), IM_COL32(138, 43, 226, 255), brandText.c_str());
            if (esp_enabled && [IL2CPPInit isInitializationComplete]) {
                @try {
                    drawPlayerRootESP(draw_list);
                } @catch (...) {}
            }
            if (silent_aim_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { installSilentAimHook(); } @catch (...) {}
            }
            if (no_spread_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { applyNoSpread(); } @catch (...) {}
            }
            if (speed_hack_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { installSpeedHackHook(); } @catch (...) {}
            }
            if (inf_ammo_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { applyInfiniteAmmo(); } @catch (...) {}
            }
            if (fast_bullet_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { applyFastBullet(); } @catch (...) {}
            }
            if (fly_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { applyFly(); } @catch (...) {}
            }
            if ((aim_enabled || aim_debug || silent_aim_enabled) && [IL2CPPInit isInitializationComplete]) {
                @try { updateAimbot(); } @catch (...) {}
            }
            if (tp_enabled && [IL2CPPInit isInitializationComplete]) {
                @try { pickTeleportTarget(); doTeleport(); } @catch (...) {}
            }
            if (tp_pendingFire && [IL2CPPInit isInitializationComplete]) {
                @try { updateTeleportFire(); } @catch (...) {}
            }
            if (aim_debug && [IL2CPPInit isInitializationComplete]) {
                @try { drawAimDebugOverlay(draw_list); } @catch (...) {}
            }
            ImGui::Render();
            ImDrawData* draw_data = ImGui::GetDrawData();
            ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
            [renderEncoder popDebugGroup];
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
        }
        [commandBuffer commit];
}
- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size
{
}
@end
