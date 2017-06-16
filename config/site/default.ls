(->
  config = do
    name: \servlet
    debug: false
    is-production: true
    facebook:
      clientID: \538062799648166
    google:
      clientID: \426879484014-vc7l8q5d8b86ke70u6sfamgbm3kt4tsr.apps.googleusercontent.com
  if module? => module.exports = config
)!
