// Copyright 2015-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

#include <hunspell/hunspell.hxx>

extern "C" {
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#define l_setcfunction(l, n, name, f) \
  (lua_pushcfunction(l, f), lua_setfield(l, (n > 0) ? n : n - 1, name))

/** spellchecker:add_dic() Lua function. */
static int ls_adddic(lua_State *L) {
  Hunspell *hs = *(Hunspell **)luaL_checkudata(L, 1, "ta_spell");
  return (hs->add_dic(luaL_checkstring(L, 2), luaL_optstring(L, 3, NULL)), 0);
}

/** spellchecker:spell() Lua function. */
static int ls_spell(lua_State *L) {
  Hunspell *hs = *(Hunspell **)luaL_checkudata(L, 1, "ta_spell");
  return (lua_pushboolean(L, hs->spell(luaL_checkstring(L, 2))), 1);
}

/** spellchecker:suggest() Lua function. */
static int ls_suggest(lua_State *L) {
  Hunspell *hs = *(Hunspell **)luaL_checkudata(L, 1, "ta_spell");
  char **slst = NULL;
  int n = hs->suggest(&slst, luaL_checkstring(L, 2));
  lua_createtable(L, n, 0);
  for (int i = 0; i < n; i++)
    lua_pushstring(L, slst[i]), lua_rawseti(L, -2, i + 1);
  hs->free_list(&slst, n);
  return 1;
}

/** spellchecker:add_word() Lua function. */
static int ls_addword(lua_State *L) {
  Hunspell *hs = *(Hunspell **)luaL_checkudata(L, 1, "ta_spell");
  return (hs->add(luaL_checkstring(L, 2)), 0);
}

static const luaL_Reg lib[] = {
  {"add_dic", ls_adddic},
  {"spell", ls_spell},
  {"suggest", ls_suggest},
  {"add_word", ls_addword},
  {NULL, NULL}
};

/** spell() Lua function. */
static int spell(lua_State *L) {
  const char *aff = luaL_checkstring(L, 1);
  const char *dic = luaL_checkstring(L, 2);
  const char *key = luaL_optstring(L, 3, NULL);
  Hunspell *hs = new Hunspell(aff, dic, key);
  *(Hunspell **)lua_newuserdata(L, sizeof(Hunspell *)) = hs;
  luaL_setmetatable(L, "ta_spell");
  return 1;
}

extern "C" {
int luaopen_spell(lua_State *L) {
  luaL_newmetatable(L, "ta_spell");
  luaL_setfuncs(L, lib, 0);
  lua_pushvalue(L, -1), lua_setfield(L, -2, "__index");
  return (lua_pushcfunction(L, spell), 1);
}

// Platform-specific Lua library entry points.
LUALIB_API int luaopen_spellcheck_spell(lua_State *L) {
  return luaopen_spell(L);
}
LUALIB_API int luaopen_spellcheck_spell64(lua_State *L) {
  return luaopen_spell(L);
}
LUALIB_API int luaopen_spellcheck_spellosx(lua_State *L) {
  return luaopen_spell(L);
}
}
