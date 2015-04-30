require! <[fs path]>

base = do
  ds: null
  aux: {}

  init: ({mongodb: config, name: name}, cb) ->
    @root = path.join process.cwd!, ".localfsdb"
    if !fs.exists-sync @root => fs.mkdir-sync @root
    if !fs.lstat-sync(@root).isDirectory! => throw new Error "#{@root} should be a directory."
    @db = db = do
      get-name: (name) ~> path.join(@root, (new Buffer(name).toString(\base64).replace(/\//g, "-")))
      read: (name) ->
        if !fs.exists-sync(@get-name(name)) => return null
        JSON.parse(fs.read-file-sync @get-name(name))
      write: (name, data) ->
        fs.write-file-sync(@get-name(name), JSON.stringify(data))
      clear: (name) -> if fs.exists-sync(@get-name(name)) => fs.unlink-sync(@get-name(name))
    cb {db}

  get-user: (username, password, usepasswd, detail, newuser, callback) ->
    user = @db.read "user/#username"
    if !user =>
      user = newuser username, password, usepasswd, detail
      @db.write "user/#username", user
    else
      if (usepasswd or user.usepasswd) and user.password != password => return callback null, false
    delete user.password
    return callback null, user

  session-store: -> do
    get: (sid, cb) ~>
      ret = @db.read "session/#sid"
      cb (if !ret => "not exists" else null), ret
    set: (sid, session, cb) ~> cb @db.write("session/#sid", session)
    destroy: (sid, cb) ~> cb @db.clear "session/#sid"

module.exports = base
