require! <[fs gcloud]>
datastore = gcloud.datastore

aux = do
  clean: (obj) ->
    for k,v of obj =>
      if typeof(v)=='object' =>
        @clean v
        if [k for k of v]length == 0 => delete obj[k]
      else if v==undefined or v==null => delete obj[k]
    obj

base = do
  ds: null
  aux: aux

  init: ({gcs: c}, cb) ->
    if c.keyFilename and !fs.exists-sync(c.keyFilename) => delete c.keyFilename
    ds = @ds = new datastore.dataset c
    cb {ds}

  get-user: (username, password, usepasswd, detail, newuser, callback) ->
    (e,t,n) <~ @ds.runQuery (@ds.createQuery <[user]> .filter "username =", username), _
    if !t.length =>
      user = @aux.clean newuser username, password, usepasswd, detail
      (e,k) <~ @ds.save { key: @ds.key([\user, null]), data: user}, _
      if e => return callback {all: "failed to create user"}, false
    else
      user = t.0.data
      if (usepasswd or user.usepasswd) and user.password != p => return callback null, false
    delete user.password
    (e,t,n) <~ @ds.runQuery (@ds.createQuery <[fav]> .filter "username =", username), _
    if e => return done null, false
    user.fav = {}
    # TODO handle next / pagination if necessaary
    t.map -> user.fav[it.data.pic] = true
    return callback null, user

  session-store: -> do
    get: (sid, cb) ~>
      (e,t,n) <- @ds.runQuery (@ds.createQuery <[session]> .filter "__key__ =", @ds.key([\session, sid])), _
      if !e and t and t.length => session = JSON.parse(new Buffer(t.0.data.session, \base64).toString \utf8)
      else => session = null
      if cb => cb e, session
    set: (sid, session, cb) ~>
      session = new Buffer(JSON.stringify session).toString \base64
      @ds.save {key: @ds.key([\session, sid]), data: {session}}, (e,k) -> if cb => cb e
    destroy: (sid, cb) ~>
      @ds.delete @ds.key([\session, sid]), (e) -> if cb => cb e

module.exports = base
