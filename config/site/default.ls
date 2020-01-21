(->
  config = do
    debug: false
    is-production: false
    domain: \servlet.local
    facebook:
      clientID: \<your-facebook-client-id>
    google:
      clientID: \<your-google-client-id>
  if module? => module.exports = config
)!
