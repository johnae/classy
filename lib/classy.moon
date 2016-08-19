merge = (t1, t2) ->
  res = {k, v for k, v in pairs t1}
  for k, v in pairs t2
    res[k] = v
  res

copy_value = (copies) =>
  return @ unless type(@) == 'table'
  return copies[@] if copies and copies[@]
  copies or= {}
  copy = setmetatable {}, getmetatable @
  copies[@] = copy
  for k, v in pairs @
    copy[copy_value(k, copies)] = copy_value v, copies
  copy

(name, class_initializer) ->
  local parent_class
  __instance = {}
  __properties = {}
  is_a = {}
  __meta = {}
  new_class = {:__properties, :is_a, :__instance, :__meta}

  static = (opts) ->
    for name, def in pairs opts
      new_class[name] = def

  instance = (opts) ->
    for name, def in pairs opts
      __instance[name] = def

  parent = (parent) -> parent_class = parent
  missing_prop = {
    get: (k) => rawget @, k
    set: (k, v) => rawset @, k, v
  }
  missing_property = (def) -> missing_prop = merge missing_prop, def

  properties = (opts={}) ->
    for k, v in pairs opts
      if type(v) == 'function'
        v = {get: v}
      if old_prop = __properties[k]
        v = merge(old_prop, v)
      __properties[k] = v

  accessors = (opts={}) ->
    for field, keys in pairs opts
      for key in *keys
        __properties[key] = {
          get: => @[field][key]
          set: (v) => @[field][key] = v
        }

  include = (tbl) ->
    for k, v in pairs tbl
      __instance[k] = v

  meta = (opts={}) ->
    for name, def in pairs opts
      __meta[name] = def

  class_initializer_env = setmetatable {
    :include
    :parent
    :instance
    :properties
    :accessors
    :meta
    :static
    :missing_property
    self: new_class
  }, __index: _G

  setfenv class_initializer, class_initializer_env
  class_initializer new_class

  is_a[new_class] = true
  new_class.__name = name
  __instance.dup = copy_value
  -- inherit parent if defined
  if parent_class
    __instance.super = parent_class.__instance
    for k, v in pairs parent_class.is_a
      is_a[k] = v
    for name, def in pairs parent_class
      new_class[name] = def unless new_class[name]
    for name, def in pairs parent_class.__properties
      __properties[name] = def unless __properties[name]
    for name, def in pairs parent_class.__instance
      __instance[name] = def unless __instance[name]
    for name, def in pairs parent_class.__meta
      __meta[name] = def unless __meta[name]

  __meta.__index = (k) =>
    -- delegate missing keys in instance
    if k == 'is_a'
      return is_a
    if v = rawget __instance, k
      return v
    -- next try properties
    if prop = rawget __properties, k
      -- check if the property has getter defined
      if type(prop) == 'table'
        return prop.get @, k if prop.get
      -- finally just return the property as is if no getter
      return prop
    missing_prop.get @, k if missing_prop.get

  __meta.__newindex = (k, v) =>
    -- first try setting properties
    if prop = rawget __properties, k
      if type(prop) == 'table'
        return prop.set @, v if prop.set
      -- if there were no setters/getters
      -- simply set the property directly
      __properties[k] = v
      return
    return missing_prop.set @, k, v if missing_prop.set
    rawset @, k, v

  __instance.initialize or= =>

  new = (...) ->
    -- allows calling new from instance context
    new_instance = setmetatable {:new}, __meta
    new_instance.initialize new_instance, ...
    new_instance
  new_class.new = new
  new_class