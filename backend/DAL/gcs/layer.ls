
main = (driver) ->
  ds = driver.ds
  return store = do
    read: (prefix, key) -> new bluebird (res, rej) ->
      (e,t,n) <~ ds.runQuery (ds.createQuery([prefix]).filter("__key__ =", ds.key([prefix,id]))), _
      res if e or !t or !t.length => null else t.0.data

    write: (prefix, key, data) -> new bluebird (res, rej) ->
      for key of data => if !data[key]? => delete data[key]
      key = ds.key(if key => [prefix, key] else [prefix])
      (e,k) <- ds.save {key, data}
      if data.key => return res data
      data.key = key.1
      (e,k) <- ds.save {key, data}
      return res data

    delete: (prefix, key) -> new bluebird (res, rej) ->
      (e,t,n) <- ds.runQuery (ds.createQuery [prefix] .filter "__key__ =", ds.key([prefix,key])), _
      if e or !t or !t.length => return res!
      ds.delete key, (e,k) -> res!

    list: (prefix, field, values) ->  new bluebird (res, rej) ->
      if field == \key =>
        (e,t,n) <- ds.get [ ds.key([prefix, key]) for key in values ]
      else
        #TODO - wait gcloud until they improve their gcloud binding
        if typeof(values) == typeof([]) and values.length => rej 'list by values doesnt supported'
        (e,t,n) <- ds.runQuery (ds.createQuery [prefix] .filter("#field =", values))
        res if e or !t or !t.length => null else t.0.data
/*
  return store = do
    patch: (id, e, t, n) ->  if e or !t or !t.length => null else t.0.data <<< {key:id}
    patches: (e, t, n) -> if e or !t or !t.length => [] else t.map(-> it.data <<< {key:it.key.path.1})
    list: do
      by-user: (user, prefix, cb) -> 
        (e,t,n) <- ds.runQuery (ds.createQuery [prefix] .filter("owner =", user)), _
        cb store.patches(e, t, n)
      by-key: (keys, prefix, cb) ->
        (e,t,n) <- ds.get [ ds.key([\palette, key]) for key in keys ], _
        cb store.patches e, t, n
    read: (prefix, id, cb) -> 
      t1 = new Date!getTime!
      (e,t,n) <~ ds.runQuery (ds.createQuery([prefix]).filter("__key__ =", ds.key([prefix,id]))), _
      cb @patch id, e, t, n
    exists: (prefix, id, cb) -> @read prefix, id, cb
    _write: (prefix, id, data, cb) ->
      # GCS not support storing undefined value in hash
      for key of data => if !(data[key]?) => delete data[key]
      key = ds.key(if id => [prefix, id] else [prefix])
      t1 = new Date!getTime!
      (e,k) <- ds.save {key, data}, _
      data.key = key.1
      return cb(if e => null else data)
    write: (prefix, id, json, cb) -> 
      if !id => return @_write prefix, id, json, cb
      (data) <~ @exists prefix, id, _
      if !data => return cb!
      @_write prefix, id, json, cb
    delete: (prefix, id, cb) -> 
      (e,t,n) <- ds.runQuery (ds.createQuery [prefix] .filter "__key__ =", ds.key([prefix,id])), _
      if e or !t or !t.length => 
        return cb!
      (e,k) <- ds.delete id
      cb!
    fav: (prefix, id, user, cb) ->
      (data) <~ @read prefix, id, _
      if !data => return cb null
      (favhash) <~ @read "fav/#prefix", user.username, _
      isOn = if favhash[id] => true else false
      if isOn => delete favhash[id]
      else favhash[id] = 1
      <~ @write "fav/#prefix", user.username, favhash, _
      data.fav = (data.fav or 0) + (if isOn => -1 else 1)
      store.write prefix, id, data, -> cb !isOn
    key: (prefix) -> return null
    palette: do
      lint: (payload) ->
        if !payload or !payload.name or !payload.[]colors.length => return false
        if payload.[]colors.filter(-> !it.hex or it.hex.length >10 or (it.semantic or "").length > 20).length => return false
        if payload.name.length > 20 or (payload.category or "").length > 20 => return false
        return true
      clean: (payload, req) ->
        cleandata = {colors: []} <<< payload{name, category}
        for item in payload.colors => cleandata.colors.push {} <<< item{hex, semantic}
        return cleandata
      create: (payload, req) ->
        cleandata = @clean payload, req
        cleandata.owner = req.user.username
        cleandata.key = store.key \palette
        return cleandata
    palettes: do
      lint: (payload) ->
        if !payload or !payload.name => return false
        if payload.[]palettes.filter(-> typeof(it) != typeof("") or it.length >= 20 ).length => return false
        return true
      clean: (payload, req) ->
        cleandata = {palettes: []} <<< payload{name}
        (palettes) <- store.list.by-key payload.[]palettes, \palette, _
        cleandata.palettes = palettes.filter(->!it.deleted)
        return cleandata
      expand: (payload) ->
        (palettes) <- store.list.by-key payload.[]palettes, \palette, _
        payload.palettes = palettes.filter(->!it.deleted)
      create: (payload, req) ->
        cleandata = @clean payload, req
        cleandata.owner = req.user.username
        cleandata.key = store.key \palettes
        return cleandata
*/

module.exports = main
