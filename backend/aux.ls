require! mongodb

base = do
  r500: (res, error) ->
    console.log:[ERROR] #error"
    res.status(500).json({detail:error})
  r404: (res) -> res.status(404)send!
  r403: (res) -> res.status(403)send!
  r400: (res) -> res.status(400)send!
  r200: (res) -> res.send!
  OID: -> mongodb.ObjectID

module.exports = base
