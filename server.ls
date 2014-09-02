require! <[./backend]>

config = {}
backend.init config
backend.app.get \/, (req, res) -> res.render 'index'

backend.start ({db, server, cols})->

