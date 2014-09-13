require! {'./backend/main'.backend, './backend/main'.aux}
require! driver: \./backend/mongodb
require! <[LiveScript fs ./secret]>

config = {debug: true, name: \servlet}
config <<< secret.config
backend.init config, driver

backend.app.get \/, (req, res) -> res.render 'index.jade', {word: "hello world"}
backend.app.get \/js, (req, res) -> res.render 'index.ls', {word: "hello world"}


backend.start ->

