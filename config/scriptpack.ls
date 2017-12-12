(->
  config = css: {}, js: {}
  config.css <<< do
    base: <[
      /assets/bootstrap/4.0.0-beta/css/bootstrap.min.css
      /assets/fontawesome/4.7.0/css/font-awesome.min.css
      /css/index.css
    ]>
  config.js <<< do
    base: <[
      /js/ldBase/index.js
      /js/ldBase/util.js
      /js/index.js
    ]>
  if module? => module.exports = config
)!
