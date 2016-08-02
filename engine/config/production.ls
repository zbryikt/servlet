(->
  config = do
    domain: \my.domain
    urlschema: "https://"
    name: \myProject
    debug: false
    facebook:
      clientID: \my-facebook-client-id
    google:
      clientID: \my-google-client-id

  if module? => module.exports = config
  else if angular? =>
    angular.module \myProject
      ..service \config <[]> ++ -> config
  else window.config = config
)!
