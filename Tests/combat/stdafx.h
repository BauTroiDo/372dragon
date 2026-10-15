#pragma once
// Standalone compilation of the production DBC/combat sources needs only
// their shared types, not the Game application's service graph or PCH.
#include "Type.h"
#include <algorithm>
#include <climits>
#include <cstring>
#define tsnprintf _snprintf
#define MAX_FILE_PATH 260
