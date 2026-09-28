//
//  ESPConfig.h
//  IL2CPP Mod Menu
//
//  ESP Configuration - Easy customization for different games
//  Just change the values below to adapt ESP to your game
//

#ifndef ESPConfig_h
#define ESPConfig_h

// ============================================================================
// MAIN CONFIGURATION - CHANGE THESE VALUES FOR YOUR GAME
// ============================================================================


// ============================================================================
// CLASSES AND ASSEMBLY CONFIGURATION - PixelStrike3D
// ============================================================================

// Main player class (Health holds all player/bot state: HP, team, isLocal, dead, transform)
#define PLAYER_CLASS_NAME "Health"
#define PLAYER_ASSEMBLY_NAME "Assembly-CSharp.dll"

// Backwards compatibility aliases
#define PLAYER_CLASS_NAME_HUNTER "Health"
#define PLAYER_CLASS_NAME_PROP "Health"

// Unity GameObject class (usually no need to change)
#define GAMEOBJECT_CLASS_NAME "UnityEngine.GameObject"
#define GAMEOBJECT_ASSEMBLY_NAME "UnityEngine"

// SkinnedMeshRenderer class for skeleton ESP
#define SKINNED_MESH_RENDERER_CLASS_NAME "UnityEngine.SkinnedMeshRenderer"

// Component class for searching components
#define COMPONENT_CLASS_NAME "UnityEngine.Component"
#define COMPONENT_ASSEMBLY_NAME "UnityEngine"

// ============================================================================
// ESP CONFIGURATION - DISTANCES AND LIMITS
// ============================================================================

// Maximum distance for ESP (in game units)
#define ESP_MAX_DISTANCE 300.0f

// Minimum number of bones for skeleton ESP
#define MIN_BONE_COUNT 5

// Maximum distance between bones for skeleton ESP
#define MAX_BONE_DISTANCE_IMPORTANT 4.0f
#define MAX_BONE_DISTANCE_NORMAL 3.0f

// ============================================================================
// ESP COLORS CONFIGURATION
// ============================================================================

// Enemy Colors (Red)
#define ESP_ENEMY_COLOR_R 255
#define ESP_ENEMY_COLOR_G 40
#define ESP_ENEMY_COLOR_B 40
#define ESP_ENEMY_COLOR_A 255

// Teammate Colors (Cyan / Blue)
#define ESP_TEAM_COLOR_R 40
#define ESP_TEAM_COLOR_G 180
#define ESP_TEAM_COLOR_B 255
#define ESP_TEAM_COLOR_A 255

// VisCheck Colors: Thấy địch = Xanh lá (Green), Bị khuất = Đỏ (Red)
#define ESP_VIS_VISIBLE_COLOR IM_COL32(0, 255, 0, 255)
#define ESP_VIS_HIDDEN_COLOR  IM_COL32(255, 30, 30, 255)

// Basic line / default color
#define ESP_LINE_COLOR_R 255
#define ESP_LINE_COLOR_G 40
#define ESP_LINE_COLOR_B 40
#define ESP_LINE_COLOR_A 255

#define ESP_DISTANCE_COLOR_R 255
#define ESP_DISTANCE_COLOR_G 255
#define ESP_DISTANCE_COLOR_B 255
#define ESP_DISTANCE_COLOR_A 255

// Skeleton Colors
#define ESP_SKELETON_COLOR_IMPORTANT_R 0
#define ESP_SKELETON_COLOR_IMPORTANT_G 255
#define ESP_SKELETON_COLOR_IMPORTANT_B 0
#define ESP_SKELETON_COLOR_IMPORTANT_A 255

#define ESP_SKELETON_COLOR_NORMAL_R 0
#define ESP_SKELETON_COLOR_NORMAL_G 200
#define ESP_SKELETON_COLOR_NORMAL_B 0
#define ESP_SKELETON_COLOR_NORMAL_A 200

// ============================================================================
// LINE THICKNESS CONFIGURATION
// ============================================================================

#define ESP_LINE_THICKNESS 1.2f
#define ESP_SKELETON_THICKNESS 1.3f


// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

// Creates full type name for IL2CPP
#define CREATE_TYPE_STRING(className, assemblyName) (className ", " assemblyName)

// ============================================================================
// CUSTOMIZATION NOTES
// ============================================================================

/*
TO CHANGE BONE RENDERING COMPONENT:
- If your game doesn't use SkinnedMeshRenderer for bones, change SKINNED_MESH_RENDERER_CLASS_NAME
- Common alternatives: "MeshRenderer", "CharacterController", or custom bone components


TO CHANGE PLAYER CLASS:
- PLAYER_CLASS_NAME: Full class name with namespace (e.g. "MyGame.Player.PlayerController")
- PLAYER_ASSEMBLY_NAME: Assembly file name (e.g. "MyGame.dll")

*/

// Color macros - Only used colors
#define ESP_LINE_COLOR IM_COL32(ESP_LINE_COLOR_R, ESP_LINE_COLOR_G, ESP_LINE_COLOR_B, ESP_LINE_COLOR_A)
#define ESP_DISTANCE_COLOR IM_COL32(ESP_DISTANCE_COLOR_R, ESP_DISTANCE_COLOR_G, ESP_DISTANCE_COLOR_B, ESP_DISTANCE_COLOR_A)

// Skeleton color macros
#define ESP_SKELETON_COLOR_IMPORTANT IM_COL32(ESP_SKELETON_COLOR_IMPORTANT_R, ESP_SKELETON_COLOR_IMPORTANT_G, ESP_SKELETON_COLOR_IMPORTANT_B, ESP_SKELETON_COLOR_IMPORTANT_A)
#define ESP_SKELETON_COLOR_NORMAL IM_COL32(ESP_SKELETON_COLOR_NORMAL_R, ESP_SKELETON_COLOR_NORMAL_G, ESP_SKELETON_COLOR_NORMAL_B, ESP_SKELETON_COLOR_NORMAL_A)



#endif /* ESPConfig_h */
