#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <zlib.h>
#include <stdlib.h>


#include "addlibs-custom.c"


static void call_deflated_chunk(lua_State *L, const char *name, int window_bits, const unsigned char* deflated, int deflated_size, int inflated_size) {
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
	  luaL_error(L, "unable to load chunk!!");
    return;
  }

  lua_call(L, 0, 0);
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

LUALIB_API void luaL_openlibs (lua_State *L) {
  const luaL_Reg *lib;
  for (lib = loadedlibs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);
  }
  for (lib = reg_add_libs; lib->func; lib++) {
    luaL_requiref(L, lib->name, lib->func, 1);
    lua_pop(L, 1);
  }
  if (chunk_deflated_size > 0 && chunk_inflated_size > 0) {
    call_deflated_chunk(L, chunk_name, chunk_window_bits, chunk_deflated, chunk_deflated_size, chunk_inflated_size);
  }
}
