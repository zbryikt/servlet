(->
  config = do
    base: <[]>

  if module? => module.exports = config
  else if angular? =>
    angular.module \myProject
      ..service \scriptpack <[]> ++ -> config
  else window.scriptpack = config
)!

