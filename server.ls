require! {'./backend/main'.backend, './backend/main'.aux}
require! driver: \./backend/mongodb
require! <[LiveScript fs ./secret]>

config = {debug: true, name: \servlet}
config <<< secret
backend.init config, driver

#deprecated
backend.app.get \/context, (req, res) -> res.render \backend.ls, {user: req.user}

# remove after forked
backend.app.get \/sample, (req, res) -> res.render 'sample.jade', {word1: "hello", context: {word2: "world"}}
backend.app.get \/sample.js, (req, res) -> res.render 'sample.ls', {word: "hello world"}

backend.app.get \/, (req, res) -> res.render 'index.jade'

backend.start ->

