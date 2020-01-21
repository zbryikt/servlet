require! <[fs ../build/pug path]>

cwd = path.resolve process.cwd!

module.exports = do
  build: (list) ->
  unlink: ->
