require! <[fs path child_process express mongodb body-parser crypto chokidar]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport LiveScript]>

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

base = do
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
    mail: do
      host: \box590.bluehost.com
      port: 465
      secure: true
      maxConnections: 5
      maxMessages: 10
      auth: {user: 'noreply@g0v.photos', pass: ''}

  init: (config) ->
    config = {} <<< @config! <<< config
    app = express!
    app.use body-parser.json!
    app.use body-parser.urlencoded extended: true
    app.set 'view engine', 'jade'
    app.engine \ls, lsc
    app.use \/, express.static("#__dirname/static")
    app.set 'views', path.join(__dirname, 'view')

    passport.use new passport-local.Strategy {
      usernameField: \email
      passwordField: \passwd
    },(u,p,done) ->
      p = crypto.createHash(\md5).update(p).digest(\hex)
      (e,r) <- base.cols.user.findOne {email: u}
      if !r =>
        user = {email: u, passwd: p, name: u.replace(/@.+$/, "")}
        (e,r) <- base.cols.user.insert user, {w: 1}
        if !r => return done {server: "failed to create user"}, false
        return done null, user
      else
        if r.passwd == p => return done null, r
        done null, false
    passport.use new passport-facebook.Strategy(
      do
        clientID: config.clientID
        clientSecret: config.clientSecret
        callbackURL: "#{config.url}u/auth/facebook/callback"
      , (access-token, refresh-token, profile, done) ->
        done null, profile
    )

    app.use express-session secret: config.session-secret, resave: false, saveUninitialized: false
    app.use passport.initialize!
    app.use passport.session!

    passport.serializeUser (u,done) -> done null, JSON.stringify(u)
    passport.deserializeUser (v,done) -> done null, JSON.parse(v)

    router = do
      user: express.Router!
      api: express.Router!

    app.use "/d", router.api
    app.use "/u", router.user
    app.get "/d/health", (req, res) -> res.json {}

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
        successRedirect: \/u/200
        failureRedirect: \/u/403

    postman = nodemailer.createTransport nodemailer-smtp-transport config.mail
    @watch!

    @ <<< {config, app, express, router, postman}

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
    watcher = chokidar.watch @watch-path, ignored: (~> @ignore-func it), persistent: true
      .on \add, @watch-handler
      .on \change, @watch-handler
  watch-handler: ->
    src = if it.0 != \/ => path.join(cwd,it) else it
    src = src.replace path.join(cwd,\/), ""
    [type,cmd] = [ftype(src), ""]
    if type == \ls => 
      des = src.replace \src/ls, \static/js
      des = des.replace /\.ls$/, ".js"
      cmd = "#ls -cbp #src > #des"
    else if type == \sass => 
      sass-tree.parse src
      srcs = sass-tree.find-root src
      srcs = srcs.map (src) ->
        des = src.replace \src/sass, \static/css
        des = des.replace /\.sass/, ".css"
        cmd = "#sass #src #des"
      cmd = srcs.join \;
    else => return
    if !cmd => return
    if des => 
      dir = path.dirname des
      if !fs.exists-sync dir => mkdir-recurse dir
    console.log "[BUILD] #cmd"
    child_process.exec cmd, log

module.exports = base
