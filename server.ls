require! <[./backend]>
require! <[LiveScript fs]>

config = {debug: false}
backend.init config

backend.app.get \/, (req, res) -> res.render 'index'
backend.app.get \/blah, (req, res) -> res.render 'index.ls'


backend.start ({db, server, cols})->

