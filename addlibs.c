// see addlibs.lua

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <zlib.h>
#include <stdlib.h>
#include <string.h>

#ifdef JLS_LUA_MOD_TRACE
#include <stdio.h>
#define trace(...) printf(__VA_ARGS__)
#else
#define trace(...) ((void)0)
#endif

struct custom_preload {
  unsigned char *name;
  int index;
  int size;
};

#include "addlibs-custom.c"

static unsigned char* inflate_chunk(const unsigned char* deflated, int deflated_size, int inflated_size) {
  int ret;
  z_stream strm;
  unsigned char* inflated;

  strm.zalloc = Z_NULL;
  strm.zfree = Z_NULL;
  strm.opaque = Z_NULL;
  strm.avail_in = 0;
  strm.next_in = Z_NULL;

  ret = inflateInit2(&strm, WINDOW_BITS);
  if ((ret != Z_OK) && (ret != Z_STREAM_END)) {
    return NULL;
  }

  inflated = malloc(inflated_size + 1);

  strm.avail_in = deflated_size;
  strm.next_in = (unsigned char*) deflated;

  strm.avail_out = inflated_size;
  strm.next_out = inflated;

  ret = inflate(&strm, Z_NO_FLUSH);
  if (ret != Z_STREAM_END) {
    free(inflated);
    return NULL;
  }
  (void) inflateEnd(&strm);

  return inflated;
}

static void load_deflated_chunk(lua_State *L, const char *name, const unsigned char* deflated, int deflated_size, int inflated_size) {
  int ret;
  unsigned char* inflated;

  inflated = inflate_chunk(deflated, deflated_size, inflated_size);
  if (inflated == NULL) {
	  luaL_error(L, "inflate error!");
    return;
  }
  ret = luaL_loadbuffer(L, (const char*)inflated, inflated_size, name);
  free(inflated);
  if (ret != LUA_OK) {
    lua_pop(L, 1); /* the error message */
	  luaL_error(L, "unable to load chunk!!");
    return;
  }
}

static int preload_custom_rawget(lua_State *L, int index, int nresults) {
  if ((index < 0) || (index > PRELOADS_INDEX)) {
	  luaL_error(L, "invalid preload index!");
    return 0;
  }
  const struct custom_preload* cp = custom_preloads + index;
  const struct custom_preload* cpn = cp + 1;
  trace("preload_custom_rawget(%d, %d) at %d, size: %d - %d\n", index, nresults, cp->index, cpn->index - cp->index, cp->size);
  load_deflated_chunk(L, cp->name, custom_chunk_preloads + cp->index, cpn->index - cp->index, cp->size);
  lua_pushstring(L, cp->name);
  lua_call(L, 1, nresults);
  return nresults;
}

static int preload_custom_get(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  const struct custom_preload* cp;
  int index;
  for (index = 0; ; index++) {
    cp = custom_preloads + index;
    if (cp->name == NULL) {
      index = -1;
      break;
    }
    if (strcmp(name, cp->name) == 0) {
      break;
    }
  }
  trace("preload_custom_get('%s') => %d\n", name, index);
  return preload_custom_rawget(L, index, 1);
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
  const struct custom_preload* cp;
  const struct custom_preload* cpn;
  unsigned char* inflated;
  const char **pname;
  const luaL_Reg *lib;
  char *env;
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);
  }
  /* custom part */
  env = getenv("JLS_STATIC_PRELOADS");
  if (env == NULL || strstr(env, "lib")) {
    luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
    for (lib = custom_libs; lib->func; lib++) {
      trace("preload lib '%s'\n", lib->name);
      lua_pushcfunction(L, lib->func);
      lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 1);
  }
  if (env == NULL || strstr(env, "lua")) {
    luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);
    for (pname = custom_names; *pname; pname++) {
      trace("preload lua '%s'\n", *pname);
      lua_pushcfunction(L, preload_custom_get);
      lua_setfield(L, -2, *pname);
    }
    lua_pop(L, 1);
    preload_custom_rawget(L, PRELOADS_INDEX, 0);
  }
  if (env != NULL && strstr(env, "show")) {
    printf("--[[\npreload C modules:\n");
    for (lib = custom_libs; lib->func; lib++) {
      printf("  \"%s\"\n", lib->name);
    }
    printf("]]\n");
    for (cp = custom_preloads; cp->name; cp++) {
      printf("package.preload[\"%s\"] = function(...)\n", cp->name);
      cpn = cp + 1;
      inflated = inflate_chunk(custom_chunk_preloads + cp->index, cpn->index - cp->index, cp->size);
      if (inflated) {
        fwrite(inflated, cp->size, 1, stdout);
        fflush(stdout);
        free(inflated);
      }
      printf("\nend\n");
    }
  }
  /* end custom part */
}
