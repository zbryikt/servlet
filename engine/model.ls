require! <[bluebird]>
# usage
# MyType = new model({
#   self: { constraint applied to object itself }
#   base: { constraint applied to object members }
#   lint: (obj) -> manually check if obj is valid.
#     return [isFailed, whichKey, whyFailed, recursiveReason]
#   create: (obj) ->
#     obj will be given default value according to self and base 
#     but one can still alter it in this function
#   expand: -> 
#     to expand foreign key
#   shrink: ->
#     convert object to foreign key
# })

# in base, self, or argument of model.type.array, we use config object like:
#   {max, min, required, type: MyType}

# return : [isFailed, whichKey, whyFailed, recursiveReason]
model = ((config)->
  @config = config
  @ <<< @config{name,range}
  @
) <<< prototype: do
  _validate: (k, v, obj) ->
    if v.required and !obj? => return [true, k, \required]
    if !obj? => return [false]
    if v.type =>
      ret = v.type.lint obj 
      if !ret or ret.0 => return [true, k, \type, ret]
    if v.max or v.min =>
      if v.type and v.type.range => 
        ret = v.type.range v{min,max}, obj
        if ret.0 => 
          ret.1 = k
          return ret
      else 
        value = if obj.length? => obj.length else obj
        if v.max and value > v.max => return [true, k, \max]
        if v.min and value < v.min => return [true, k, \min]
    return [false]

  validate: (obj) ->
    if @config.self => 
      ret = @_validate null, that, obj
      if ret.0 => return ret
    for item in [[null, @config.self, obj]] ++ [[k,v, obj[k]] for k,v of @config.{}base] => if item.1 =>
      ret = @_validate item.0, item.1, item.2
      if ret.0 => return ret
    return [false]

  lint: (obj) ->
    ret = @validate(obj)
    if !ret or ret.0 => return ret
    if @config.lint => return @config.lint obj
    return [false, null, null]

  clean: (obj) ->
    if @config.clean => obj = that obj
    if @interface => obj <<< {get-type: ~>@} <<< @interface
    return obj

  create: ->
    obj = {}
    for k,v of @config.{}base => 
      if v.default? => obj[k] = v.default 
      else if v.{}type.{}config.{}self.default => obj[k] = that
    obj = if @config.create => that obj else obj
    return @clean obj

  expand: (obj) -> new bluebird (res, rej) ~>
    (obj) <~ (if @config.expand => that obj else new bluebird (res,rej) -> res obj).then
    if !obj => promises = []
    else promises = [[k,v] for k,v of @config.{}base].filter(-> it.1.type and obj[it.0]).map(->
      ret = it.1.type.expand(obj[it.0])
      ret.then (ret) -> obj[it.0] = ret
    )
    if promises.length => bluebird.all promises .then -> res obj
    else res obj

  shrink: (obj) ->
    if @config.shrink => obj = that obj
    for k,v of @config.{}base => if obj[k] => obj[k] = v.type.shrink obj[k]
    obj

model.type = {} <<< do
  boolean: new model do
    lint: -> [!(!it or (typeof(it) == typeof(true)))]

  string: new model do
    lint: -> [!(typeof(it) == typeof("") or typeof(it) == typeof(1))]
    range: ({min,max}, value) -> 
      length = "#value".length
      if length < min => return [true,null,\min]
      if length > max => return [true,null,\max]
      return [false]

  email: new model do
    link: -> [!(it and typeof(it)==typeof("") and /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+/.exec(it))]

  number: new model do
    lint: -> [!(typeof(it) == typeof(0))]

  date: new model do
    lint: ->
      if typeof(it) == typeof("") and !isNaN(new Date(it)) and it.length < 50 => return [false]
      return [isNaN(it)]

  array: (m) -> new model do
    lint: (obj) -> 
      if typeof(obj) != typeof([]) or isNaN(parseInt(obj.length)) => return [true]
      ret = (for idx from 0 til obj.length => [idx, m.type.lint(obj[idx])]).filter(-> it.1.0)[0]
      if !ret => return [false]
      return [true, ret.0, ret.1]

  key: (m) -> new model do
    lint: (obj) ->
      if typeof(obj) == typeof({}) or typeof(obj) == typeof("") => return [false]
      return [true,null,\type]
    expand: (obj) -> if typeof(obj) == typeof("") => m.type.expand obj
  keys: (m) -> new model do
    lint: (obj) -> 
      if typeof(obj) != typeof([]) or isNaN(parseInt(obj.length)) => return [true]
      ret = (for idx from 0 til obj.length => [idx, obj[idx]]).filter(->!it.1)[0]
      if !ret => return [false]
      return [true, ret.0, ret.1]
    expand: (obj) -> 
      promises = [ [idx,m.type.expand(obj[idx])] for idx from 0 til obj.length ].map(->
        it.1.then (ret) -> obj[it.0] = ret
      )
      new bluebird (res, rej) -> bluebird.all promises .then -> res obj
    shrink: (obj) -> for idx from 0 til obj.length => obj[idx] = m.type.shrink obj[idx]

  id: new model do
    lint: -> [false]

module.exports = model
