require! <[fs path child_process express mongodb body-parser crypto chokidar]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport LiveScript]>
require! <[connect-multiparty]>
require! <[./aux ./watch]>

RegExp.escape = -> it.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

lsc = (path, options, callback) ->
  opt = {} <<< options
  delete opt.settings
  try
    [err,ret] = [null, LiveScript.compile((fs.read-file-sync path .toString!))]
    ret = "var req = #{JSON.stringify(opt)}; #ret"
  catch e
    [err,ret] = [e,""]
  callback err, ret

backend = do
  # data driver. initialized in init, determined by config
  dd: null

  # wrapper or http request handler for checking if is logined as staff 
  authorized: (cb) -> (req, res) ->
    if not (req.user and req.user.isStaff) => return res.status(403).render('403', {url: req.originalUrl})
    cb req, res

  update-user: (req) -> req.logIn req.user, ->

  # sample configuration
  config: -> do
    clientID: \252332158147402
    clientSecret: \763c2bf3a2a48f4d1ae0c6fdc2795ce6
    session-secret: \featureisameasurableproperty
    url: \http://localhost/
    name: \servlet
    port: \9000
    debug: true
    limit: '20mb'

    cookie:
      domain: \.g0v.photos

    mongodb:
      url: \mongodb://localhost/

    gcs: do
      projectId: \keen-optics-617
      keyFilename: \/Users/tkirby/.ssh/google/g0vphotos/key.json

    mail: do
      host: \box590.bluehost.com
      port: 465
      secure: true
      maxConnections: 5
      maxMessages: 10
      auth: {user: 'noreply@g0v.photos', pass: ''}

  newUser: (username, password, usepasswd, detail) ->
    name = if detail => detail.displayName or detail.username else username.replace(/@.+$/, "")
    user = {username, password, usepasswd, displayname, detail, create_date: new Date!}

  getUser: (username, password, usepasswd, detail, done) ->
    password = if usepasswd => crypto.createHash(\md5).update(password).digest(\hex) else ""
    @dd.get-user username, password, usepasswd, detail, @newUser, done


  session-store: -> @ <<< @dd.session-store!

  init: (config, driver) ->
    config = {} <<< @config! <<< config
    @dd = driver
    aux <<< driver.aux

    @session-store.prototype = express-session.Store.prototype

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
        callbackURL: "/u/auth/facebook/callback"
        profileFields: ['id', 'displayName', 'link', 'emails']
      , (access-token, refresh-token, profile, done) ~>
        @getUser profile.emails.0.value, null, false, profile, @newuser, done
    )

    app.use express-session 
      secret: config.session-secret
      resave: true
      saveUninitialized: true
      store: new @session-store!
      cookie: do
        #secure: true # TODO: https. also need to dinstinguish production/staging
        path: \/
        httpOnly: true
        maxAge: 86400000 * 30 * 12 #  1 year
        domain: config.cookie.domain if config.{}cookie.domain
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
      ..get \/auth/facebook, passport.authenticate \facebook, {scope: ['email']}
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

    @ <<< {config, app, express, router, postman, multi}

  start: (cb) ->
    if !@config.debug => @app.use (err, req, res, next) -> if err => res.status 500 .render '500' else next!
    @dd.init @config, ~> @ <<< it
    @watch.start!
    server = @app.listen @config.port, -> console.log "listening on port #{server.address!port}"
    cb @

module.exports = {backend, aux}
