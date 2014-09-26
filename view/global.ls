angular.module \backend
  ..factory \global, <[context]> ++ (context) ->
    delete req.cache
    delete req._locals
    copy = {} <<< context
    context <<< req <<< copy
    req
