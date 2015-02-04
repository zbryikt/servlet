require! <[LiveScript fs ./secret]>
require! './backend/main': {backend, aux}
require! './backend/mongodb': driver

config = {debug: true, name: \servlet}
config <<< secret
backend.init config, driver, ->

backend.app.get \/, (req, res) ->
  if !req.session.root => req.session.root = 0
  req.session.root += 1
  console.log req.session
  res.json {ok:1}

backend.app.get \/global, aux.type.json, (req, res) -> res.render \global.ls, {user: req.user, global: true}

# remove after forked
backend.app.get \/sample, (req, res) -> res.render 'sample/index.jade', {word1: "hello", context: {word2: "world"}}
backend.app.get \/sample.js, aux.type.json, (req, res) -> res.render 'sample/index.ls', {word: "hello world"}
# if serve static file via express 
# backend.app.use express.static __dirname + '/static'

backend.app.get \/, (req, res) -> res.render 'index.jade'

backend.start ->

