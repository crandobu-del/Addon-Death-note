import fengari from 'fengari';
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = fengari;

export function createEngine(sources) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  lua.lua_newtable(L); lua.lua_setglobal(L, to_luastring('SR_DEV_NAMESPACE'));
  function error() { const message = to_jsstring(lua.lua_tostring(L, -1)); lua.lua_settop(L, 0); throw new Error(message); }
  function load(source, label) {
    if (lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring(label)) !== lua.LUA_OK) error();
  }
  function read(index, seen = new Set()) {
    const absolute = lua.lua_absindex(L, index);
    switch (lua.lua_type(L, absolute)) {
      case lua.LUA_TNIL: return null;
      case lua.LUA_TBOOLEAN: return !!lua.lua_toboolean(L, absolute);
      case lua.LUA_TNUMBER: return lua.lua_tonumber(L, absolute);
      case lua.LUA_TSTRING: return to_jsstring(lua.lua_tostring(L, absolute));
      case lua.LUA_TTABLE: {
        const pointer = lua.lua_topointer(L, absolute);
        if (seen.has(pointer)) throw new Error('Cyclic Lua result');
        seen.add(pointer); const entries = [];
        lua.lua_pushnil(L);
        while (lua.lua_next(L, absolute)) { entries.push([read(-2, seen), read(-1, seen)]); lua.lua_pop(L, 1); }
        seen.delete(pointer);
        const array = entries.length > 0 && entries.every(([key]) => Number.isInteger(key) && key >= 1 && key <= entries.length);
        if (array) { const value = []; for (const [k,v] of entries) value[k-1] = v; return value; }
        return Object.fromEntries(entries);
      }
      default: throw new Error('Unsupported Lua result');
    }
  }
  function push(value) {
    if (value === null || value === undefined) lua.lua_pushnil(L);
    else if (typeof value === 'string') lua.lua_pushstring(L, to_luastring(value));
    else if (typeof value === 'number' && Number.isFinite(value)) lua.lua_pushnumber(L, value);
    else if (typeof value === 'boolean') lua.lua_pushboolean(L, value);
    else if (typeof value === 'object') {
      lua.lua_newtable(L);
      for (const [key, v] of Object.entries(value)) { push(Array.isArray(value) ? Number(key)+1 : key); push(v); lua.lua_settable(L, -3); }
    } else throw new Error('Unsupported host value');
  }
  for (const { name, source } of sources) {
    load(source, name); lua.lua_pushstring(L, to_luastring('SyndicatRouge'));
    lua.lua_getglobal(L, to_luastring('SR_DEV_NAMESPACE'));
    if (lua.lua_pcall(L, 2, 0, 0) !== lua.LUA_OK) error();
  }
  return {
    test(source) {
      load(source, 'core_spec.lua'); lua.lua_getglobal(L, to_luastring('SR_DEV_NAMESPACE'));
      if (lua.lua_pcall(L, 1, 1, 0) !== lua.LUA_OK) error();
      const result = read(-1); lua.lua_settop(L, 0); return result;
    },
    call(module, method, ...args) {
      lua.lua_getglobal(L, to_luastring('SR_DEV_NAMESPACE')); lua.lua_getfield(L, -1, to_luastring(module));
      lua.lua_getfield(L, -1, to_luastring(method)); for (const arg of args) push(arg);
      if (lua.lua_pcall(L, args.length, lua.LUA_MULTRET, 0) !== lua.LUA_OK) error();
      const values = []; for (let index=3; index<=lua.lua_gettop(L); index++) values.push(read(index));
      lua.lua_settop(L, 0); return values;
    },
    close() { lua.lua_close(L); }
  };
}
