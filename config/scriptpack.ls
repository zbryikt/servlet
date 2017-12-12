(->
  config = css: {}, js: {}
  config.js <<< do
    base: <[
      /js/ldBase/index.js
      /js/ldBase/util.js
      /js/index.js
    ]>
  if module? => module.exports = config
)!
