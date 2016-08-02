(->
  config = do
    domain: \localhost
    urlschema: "http://"
    name: \myproject
    debug: true
    facebook:
      clientID: \facebook-client-id
    google:
      clientID: \google-client-id

  if module? => module.exports = config
  else if angular? =>
    try
      angular.module \myProject
        ..service \config <[]> ++ -> config
    catch e
  if window? => window.config = config
)!
