require! <[fs path child_process express mongodb body-parser crypto chokidar]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport LiveScript]>
require! <[connect-multiparty]>

RegExp.escape = -> it.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

ls   = if fs.existsSync v=\node_modules/.bin/livescript => v else \livescript
jade = if fs.existsSync v=\node_modules/.bin/jade => v else \jade
sass = if fs.existsSync v=\node_modules/.bin/sass => v else \sass
cwd = path.resolve process.cwd!
cwd-re = new RegExp RegExp.escape "#cwd#{if cwd[* - 1]=='/' => "" else \/}"
if process.env.OS=="Windows_NT" => [jade,sass,ls] = [jade,sass,ls]map -> it.replace /\//g,\\\
log = (error, stdout, stderr) -> if "#{stdout}\n#{stderr}".trim! => console.log that
mkdir-recurse = ->
  if !fs.exists-sync(it) => 
    mkdir-recurse path.dirname it
    fs.mkdir-sync it

sass-tree = do
  down-hash: {}
  up-hash: {}
  parse: (filename) ->
    dir = path.dirname(filename)
    ret = fs.read-file-sync filename .toString!split \\n .map(-> /^ *@import (.+)/.exec it)filter(->it)map(->it.1)
    ret = ret.map -> path.join(dir, it.replace(/(\.sass)?$/, ".sass"))
    @down-hash[filename] = ret
    for it in ret => if not (filename in @up-hash.[][it]) => @up-hash.[][it].push filename
  find-root: (filename) ->
    work = [filename]
    ret = []
    while work.length > 0
      f = work.pop!
      if @up-hash.[][f].length == 0 => ret.push f
      else work ++= @up-hash[f]
    ret

lsc = (path, options, callback) ->
  opt = {} <<< options
  delete opt.settings
  try
    [err,ret] = [null, LiveScript.compile((fs.read-file-sync path .toString!))]
    ret = "var req = #{JSON.stringify(opt)}; #ret"
  catch e
    [err,ret] = [e,""]
  callback err, ret

ftype = ->
  switch
  | /\.ls$/.exec it => "ls"
  | /\.sass$/.exec it => "sass"
  | /\.jade$/.exec it => "jade"
  | otherwise => "other"

#TODO implement this
session-store = (ds) -> @ <<<
  ds: ds
  get: (sid, cb) ->
  set: (sid, session, cb) ->
  destroy: (sid, cb) ->
session-store.prototype = express-session.Store.prototype

base = do
  r500: (res, error) ->
    console.log:[ERROR] #error"
    res.status(500).json({detail:error})
  r404: (res) -> res.status(404)send!
  r403: (res) -> res.status(403)send!
  r400: (res) -> res.status(400)send!
  r200: (res) -> res.send!
  OID: -> mongodb.ObjectID

  authorized: (cb) -> (req, res) ->
    if not (req.user and req.user.isStaff) => return res.status(403).render('403', {url: req.originalUrl})
    cb req, res

  context-wrapper: (obj) ->
    "angular.module('backend', []).factory('context', function() { return #{JSON.stringify(obj)}; });"

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

  update-user: (req) -> req.logIn req.user, ->

  # sample configuration
  config: -> do
    clientID: \252332158147402
    clientSecret: \763c2bf3a2a48f4d1ae0c6fdc2795ce6
    session-secret: \featureisameasurableproperty
    url: \http://localhost/
    name: \servlet
    mongodbUrl: \mongodb://localhost/
    port: \9000
    debug: true
    limit: '20mb'
    mail: do
      host: \box590.bluehost.com
      port: 465
      secure: true
      maxConnections: 5
      maxMessages: 10
      auth: {user: 'noreply@g0v.photos', pass: ''}

  getUser: (u, p, usepasswd, detail, done) ->
    if usepasswd => p = crypto.createHash(\md5).update(p).digest(\hex)
    (e,r) <- base.cols.user.findOne {email: u}
    if !r =>
      name = if detail => detail.displayName or detail.username else u.replace(/@.+$/, "")
      user = {email: u, passwd: p, usepasswd, name, detail}
      (e,r) <- base.cols.user.insert user, {w: 1}
      if !r => return done {server: "failed to create user"}, false
      return done null, user
    else
      if !usepasswd or r.passwd == p => return done null, r
      done null, false

  init: (config) ->
    config = {} <<< @config! <<< config
    app = express!
    app.use body-parser.json limit: config.limit
    app.use body-parser.urlencoded extended: true, limit: config.limit
    app.set 'view engine', 'jade'
    app.engine \ls, lsc
    app.use \/, express.static("#__dirname/static")
    app.set 'views', path.join(__dirname, 'view')

    passport.use new passport-local.Strategy {
      usernameField: \email
      passwordField: \passwd
    },(u,p,done) ~> @getUser u, p, true, null, done

    passport.use new passport-facebook.Strategy(
      do
        clientID: config.clientID
        clientSecret: config.clientSecret
        callbackURL: "#{config.url}u/auth/facebook/callback"
      , (access-token, refresh-token, profile, done) ~>
        @getUser profile.emails.0.value, null, false, profile, done
    )

    app.use express-session secret: config.session-secret, resave: false, saveUninitialized: false
    app.use passport.initialize!
    app.use passport.session!

    passport.serializeUser (u,done) -> done null, JSON.stringify(u)
    passport.deserializeUser (v,done) -> done null, JSON.parse(v)

    router = do
      user: express.Router!
      api: express.Router!

    app
      ..use "/d", router.api
      ..use "/u", router.user
      ..get "/d/health", (req, res) -> res.json {}
      ..get \/context, (req, res) -> res.render \backend.ls, {user: req.user}

    router.user
      ..get \/null, (req, res) -> res.json {}
      ..get \/me, (req,res) ->
        info = if req.user => req.user{email} else {}
        res.set("Content-Type", "text/javascript").send(
          "angular.module('main').factory('user',function() { return "+JSON.stringify(info)+" });"
        )
      ..get \/200, (req,res) -> res.json(req.user)
      ..get \/403, (req,res) -> res.status(403)send!
      ..get \/login, (req, res) -> res.render \login
      ..post \/login, passport.authenticate \local, do
        successRedirect: \/u/200
        failureRedirect: \/u/403
      ..get \/logout, (req, res) ->
        req.logout!
        res.redirect \/
      ..get \/auth/facebook, passport.authenticate \facebook
      ..get \/auth/facebook/callback, passport.authenticate \facebook, do
        successRedirect: \/
        failureRedirect: \/u/403

    postman = nodemailer.createTransport nodemailer-smtp-transport config.mail

    multi = do
      parser: connect-multiparty limit: config.limit
      clean: (req, res, next) ->
        for k,v of req.files => if fs.exists-sync v.path => fs.unlink v.path
      cleaner: (cb) -> (req, res, next) ~>
        if cb => cb req, res, next
        @clean req, res, next

    @watch!
    @ <<< {config, app, express, router, postman, multi}

  start: (cb) ->

    if !@config.debug => 
      @app.use (err, req, res, next) -> if err => res.status 500 .render '500' else next!

    server = @app.listen @config.port, -> console.log "listening on port #{server.address!port}"
    mongodb.MongoClient.connect "#{@config.mongodbUrl}#{@config.name}", (e, db) ~> 
      if !db => 
        console.log "[ERROR] can't connect to mongodb server:"
        throw new Error e
      (e, c) <~ db.collection \user
      cols = {user: c}
      @ <<< {server, db, cols}
      cb {db, server, cols}

  ignore-list: [/^server.ls$/, /^library.jade$/, /^(.+\/)*?\.[^/]+$/, /^node_modules\//, /^static\//]
  ignore-func: (f) -> @ignore-list.filter(-> it.exec f.replace(cwd-re, "")replace(/^\.\/+/, ""))length
  watch-path: \src
  watch: ->
    # Q: maybe it's not right to create both media and src + static here ?
    <[media src src/ls src/sass static static/css static/js]>.map ->
      if !fs.exists-sync it => fs.mkdir-sync it
    watcher = chokidar.watch @watch-path, ignored: (~> @ignore-func it), persistent: true
      .on \add, @watch-handler
      .on \change, @watch-handler
  watch-handler: ->
    src = if it.0 != \/ => path.join(cwd,it) else it
    src = src.replace path.join(cwd,\/), ""
    [type,cmd,dess] = [ftype(src), "",[]]
    if type == \ls => 
      des = src.replace \src/ls, \static/js
      des = des.replace /\.ls$/, ".js"
      cmd = "#ls -cbp #src > #des"
      dess.push des
    else if type == \sass => 
      sass-tree.parse src
      srcs = sass-tree.find-root src
      cmd = srcs.map (src) ->
        des = src.replace \src/sass, \static/css
        des = des.replace /\.sass/, ".css"
        dess.push des
        "#sass #src #des"
      cmd = cmd.join \;
    else => return
    if !cmd => return
    if dess.length => for dir in dess.map(->path.dirname it) =>
      if !fs.exists-sync dir => mkdir-recurse dir
    console.log "[BUILD] #cmd"
    child_process.exec cmd, log

module.exports = base
