// CYS: compiles the generated ABI size checks of the shared wire/DB structs (abi_asserts.h, produced by
// CYS: Tests/abi/gen_abi_asserts.py from Registry/abi/struct_sizes_x86.json / _x64.json; Docs/04 section 6).
// CYS: Part of cys_wxnetpackets, so a size change fails the x86 and the x64 build alike.
#include "stdafx.h"
#include "abi_asserts.h"
