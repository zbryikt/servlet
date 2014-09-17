angular.module \backend
  ..factory \global, <[context]> ++ (context) ->
    delete req.cache
    delete req._locals
    context <<< req
    req
