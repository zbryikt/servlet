require! <[fs path]>

mkdir-recurse = (f) ->
  if fs.exists-sync f => return
  parent = path.dirname(f)
  if !fs.exists-sync parent => mkdir-recurse parent
  fs.mkdir-sync f

base = do
  ds: null
  aux: {}

  init: ({mongodb: config, name: name}, cb) ->
    @root = path.join process.cwd!, ".localfsdb"
    if !fs.exists-sync @root => fs.mkdir-sync @root
    if !fs.lstat-sync(@root).isDirectory! => throw new Error "#{@root} should be a directory."
    @db = db = do
      get-name: (name, type=null) ~> path.join(@root, (type or ''), (new Buffer(name).toString(\base64).replace(/\//g, "-")))
      get-dir: (type=null) ~> path.join(@root, type or '')
      exists: (name, type=null) -> return fs.exists-sync(@get-name(name,type))
      delete: (name, type=null) -> if fs.exists-sync(@get-name(name,type)) => fs.unlink-sync @get-name(name,type)
      read: (name, type=null) ->
        if !fs.exists-sync(@get-name(name,type)) => return null
        JSON.parse(fs.read-file-sync @get-name(name,type))
      write: (name, data, type=null) ->
        if !fs.exists-sync(@get-dir(type)) => mkdir-recurse(@get-dir(type))
        fs.write-file-sync(@get-name(name,type), JSON.stringify(data))
      query: (criteria, type=null) ->
        dir = @get-dir(type)
        if !fs.exists-sync(dir) or !fs.stat-sync(dir)is-directory! => return []
        files = fs.readdir-sync(dir).map(-> "#dir/#it").filter(-> !fs.stat-sync(it)is-directory!)
        ret = []
        for file in files =>
          try 
            ret.push JSON.parse( fs.read-file-sync file .toString! )
          catch
        ret = ret.filter(->it).filter(criteria)
        return ret
      clear: (name,type=null) -> if fs.exists-sync(@get-name(name,type)) => fs.unlink-sync(@get-name(name,type))
    cb {db}

  get-user: (username, password, usepasswd, detail, newuser, callback) ->
    user = @db.read "#username", \user
    if !user =>
      user = newuser username, password, usepasswd, detail
      @db.write "#username", user, \user
    else
      if (usepasswd or user.usepasswd) and user.password != password => return callback null, false
    delete user.password
    return callback null, user

  session-store: -> do
    get: (sid, cb) ~>
      ret = @db.read sid, \session
      cb null, ret
      #cb (if !ret => "not exists" else null), ret
    set: (sid, session, cb) ~> cb @db.write(sid, session, \session)
    destroy: (sid, cb) ~> cb @db.clear sid, \session

module.exports = base
