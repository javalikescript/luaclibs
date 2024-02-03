#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <zlib.h>
#include <stdlib.h>
#include <string.h>

static void load_deflated_chunk(lua_State *L, const char *name, int window_bits, const unsigned char* deflated, int deflated_size, int inflated_size) {
  int ret;
  z_stream strm;
  unsigned char* inflated;

  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.avail_in = 0;
  strm.next_in = Z_NULL;

  ret = inflateInit2(&strm, window_bits);
  if ((ret != Z_OK) && (ret != Z_STREAM_END)) {
	  luaL_error(L, "inflate init error!");
    return;
  }

  inflated = malloc(inflated_size + 1);

  strm.avail_in = deflated_size;
  strm.next_in = (unsigned char*) deflated;

  strm.avail_out = inflated_size;
  strm.next_out = inflated;

  ret = inflate(&strm, Z_NO_FLUSH);
  if (ret != Z_STREAM_END) {
    free(inflated);
	  luaL_error(L, "inflate error!");
    return;
  }
  (void) inflateEnd(&strm);

  ret = luaL_loadbuffer(L, (const char*)inflated, inflated_size, name);
  free(inflated);
  if (ret != LUA_OK) {
    lua_pop(L, 1); /* the error message */
	  luaL_error(L, "unable to load chunk!!");
    return;
  }
}

struct custom_preload {
  unsigned char *name;
  int index;
  int size;
};

static int preload_custom_get(lua_State *L);

#include "addlibs-custom.c"

static void preload_custom_rawget(lua_State *L, int index) {
  const struct custom_preload* cp = custom_preloads + index;
  const struct custom_preload* cpn = cp + 1;
  //printf("preload_custom_rawget(%d) at %d, size: %d - %d\n", index, cp->index, cpn->index - cp->index, cp->size);
  load_deflated_chunk(L, cp->name, WINDOW_BITS, custom_chunk_preloads + cp->index, cpn->index - cp->index, cp->size);
}

static int preload_custom_find_index(const char *name) {
  const struct custom_preload* cp;
  for (int index = 0; ; index++) {
    cp = custom_preloads + index;
    if (cp->name == NULL) {
      break;
    }
    if (strcmp(name, cp->name) == 0) {
      return index;
    }
  }
  return -1;
}

static int preload_custom_get(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  int index = preload_custom_find_index(name);
  //printf("preload_custom_get(%s) => %d\n", name, index);
  if ((index < 0) || (index > PRELOADS_INDEX)) {
	  luaL_error(L, "invalid preload index!");
    return 0;
  }
  preload_custom_rawget(L, index);
  lua_call(L, 0, 1);
  return 1;
}

/* override Lua openlibs to add user libraries */

static const luaL_Reg loadedlibs[] = {
  {LUA_GNAME, luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_COLIBNAME, luaopen_coroutine},
  {LUA_TABLIBNAME, luaopen_table},
  {LUA_IOLIBNAME, luaopen_io},
  {LUA_OSLIBNAME, luaopen_os},
  {LUA_STRLIBNAME, luaopen_string},
  {LUA_MATHLIBNAME, luaopen_math},
  {LUA_UTF8LIBNAME, luaopen_utf8},
  {LUA_DBLIBNAME, luaopen_debug},
	{NULL, NULL}
};

LUALIB_API void luaL_openlibs(lua_State *L) {
  const luaL_Reg *lib;
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);
  }
  /* custom part */
  if (getenv("JLS_STATIC_NO_LIBS") == NULL) {
    load_custom_libs(L);
  }
  if (getenv("JLS_STATIC_NO_PRELOADS") == NULL) {
    load_custom_mods(L);
    preload_custom_rawget(L, PRELOADS_INDEX);
    lua_call(L, 0, 0);
  }
  /* end custom part */
}
