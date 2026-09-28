#pragma once
#include <string>

// Dumper Unity IL2CPP -> Documents/*.txt
// Dùng cho PixelStrike3D (Unity IL2CPP)

bool UnityDumper_IsDumping();
std::string UnityDumper_GetStatus();
std::string UnityDumper_GetLastPath();

// Gọi từ menu (sẽ tự chạy background thread, không treo game)
void UnityDumper_StartDump();

// Hàm đồng bộ (chạy trực tiếp, nên gọi trong background thread)
bool UnityDumper_DumpNow(std::string &outPath, std::string &outMsg);
