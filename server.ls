require! <[./backend]>
require! <[LiveScript fs]>

config = {debug: true}
backend.init config

backend.app.get \/, (req, res) -> res.render 'index.jade', {word: "hello world"}
backend.app.get \/js, (req, res) -> res.render 'index.ls', {word: "hello world"}


backend.start ({db, server, cols})->

