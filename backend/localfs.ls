require! <[fs]>

base = do
  ds: null
  aux: {}

  init: ({mongodb: config, name: name}, cb) ->
    (e, db) <~ mongodb.MongoClient.connect "#{config.url}#{name}"
    if !db => 
      console.log "[ERROR] can't connect to mongodb server:"
      throw new Error e
    (e, user) <~ db.collection \user
    (e, session) <~ db.collection \session
    @ds = ds = {user, session}
    @db = db
    cb {ds, db}

  get-user: (username, password, usepasswd, detail, newuser, callback) ->
    (e,user) <~ @ds.user.findOne {username: username}
    if !user =>
      user = newuser username, password, usepasswd, detail
      (e,r) <- @ds.user.insert user, {w: 1}
      if !r => return callback {server: "failed to create user"}, false
    else
      if (usepasswd or user.usepasswd) and user.password != password => return callback null, false
    delete user.password
    return callback null, user

  session-store: -> do
    get: (sid, cb) ~> @ds.session.findOne {sid}, cb
    set: (sid, session, cb) ~> @ds.session.update {sid}, {$set: session}, {w:1}, cb
    destroy: (sid, cb) ~> @ds.session.remove {sid}, {w:1}, cb

module.exports = base
