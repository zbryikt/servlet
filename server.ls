require! {'./backend/main'.backend, './backend/main'.aux}
require! driver: \./backend/mongodb
require! <[LiveScript fs ./secret]>

config = {debug: true, name: \servlet}
config <<< secret
backend.init config, driver

backend.app.get \/global, (req, res) -> res.render \global.ls, {user: req.user}

# remove after forked
backend.app.get \/sample, (req, res) -> res.render 'sample/index.jade', {word1: "hello", context: {word2: "world"}}
backend.app.get \/sample.js, aux.type.json, (req, res) -> res.render 'sample/index.ls', {word: "hello world"}

backend.app.get \/, (req, res) -> res.render 'index.jade'

backend.start ->

