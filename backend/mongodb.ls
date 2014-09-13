base = do
  ds: null
  aux: {}

  init: ({mongodb: config, name: name}, cb) ->
    mongodb.MongoClient.connect "#{config.url}#{name}", (e, db) ~> 
      if !db => 
        console.log "[ERROR] can't connect to mongodb server:"
        throw new Error e
      (e, user) <~ db.collection \user
      (e, session) <~ db.collection \session
      ds = {user, session}
      cb {ds}

  stream-writer: (res, stream) ->
    first = true
    res.write("[")
    stream.on \data, (it) ->
      if first == true => first := false
      else res.write(",")
      res.write(JSON.stringify it)
    stream.on \end, -> 
      res.write("]")
      res.send!

  get-user: (username, password, usepasswd, detail, newuser, callback) ->
    (e,user) <- @cols.user.findOne {username: username}
    if !user =>
      user = newuser username, password, usepasswd, detail
      (e,r) <- @cols.user.insert user, {w: 1}
      if !r => return done {server: "failed to create user"}, false
    else
      if (usepasswd or user.usepasswd) and user.password != password => return done null, false
    delete user.password
    return done null, user

  session-store: -> do
    get: (sid, cb) ~> @cols.session.findOne {sid}, cb
    set: (sid, session, cb) ~> @cols.session.update {sid}, {$set: session}, {w:1}, cb
    destroy: (sid, cb) ~> @cols.session.remove {sid}, {w:1}, cb

module.exports = base
