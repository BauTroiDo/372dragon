#include <string.h>
extern "C"
{
#include "lua.h"
#include "lauxlib.h"
}
#include "Map.h"
static char meta[] = "map_meta";

static int
lnew(lua_State *L)
{
    Map** m = (Map **)lua_newuserdata(L, sizeof(Map*));
    (*m) = new Map;
    (*m)->CleanUp();
    luaL_setmetatable(L, meta);
    return 1;
}

static int map_gc(lua_State *L)
{
    Map **m = (Map **)lua_touserdata(L, 1);
    delete *m;
    return 0;
}

static int map_load(lua_State *L)
{
    Map**m = (Map**)lua_touserdata(L, 1);
    const char *filename = lua_tostring(L, 2);
    bool r = (*m)->Load(filename);
    lua_pushboolean(L, r);
    return 1;
}

static void to_world_pos(lua_State *L, WORLD_POS &pos, int idx)
{
    luaL_checktype(L, idx, LUA_TTABLE);
    lua_getfield(L, idx, "x");
    pos.m_fX = lua_tonumber(L, -1);
    lua_pop(L, 1);
    lua_getfield(L, idx, "y");
    pos.m_fZ = lua_tonumber(L, -1);
    lua_pop(L, 1);
}

static void to_lua_world_pos(lua_State *L, WORLD_POS *posNode, int num)
{
    lua_newtable(L);
    for (int i = 0; i < num; i++)
    {
        lua_pushnumber(L, i + 1);
        {
            lua_newtable(L);
            lua_pushstring(L, "x");
            lua_pushnumber(L, posNode[i].m_fX);
            lua_settable(L, -3);

            lua_pushstring(L, "y");
            lua_pushnumber(L, posNode[i].m_fZ);
            lua_settable(L, -3);
        }
        lua_settable(L, -3);
    }
}

static int map_findpath(lua_State *L)
{
    Map** m = (Map**)lua_touserdata(L, 1);
    WORLD_POS start;
    to_world_pos(L, start, 2);
    WORLD_POS target;
    to_world_pos(L, target, 3);
    int numNode = 0;
    WORLD_POS posNode[MAX_CHAR_PATH_NODE_NUMBER];
    bool r = (*m)->FindPath(&start, &target, posNode, numNode, 0);
    //printf("r = %d, numNode = %d\n", r, numNode);
    to_lua_world_pos(L, posNode, numNode);
    return 1;
}

static luaL_Reg libs[] = {
    {"new", lnew},
    {NULL, NULL}};

static luaL_Reg meta_libs[] = {
    {"__gc", map_gc},
    {"load", map_load},
    {"findpath", map_findpath},
    {NULL, NULL}};

extern "C" int
luaopen_map(lua_State *L)
{
    luaL_newlib(L, libs);

    luaL_newmetatable(L, meta);
    luaL_setfuncs(L, meta_libs, 0);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");

    lua_pop(L, 1);
    return 1;
}
