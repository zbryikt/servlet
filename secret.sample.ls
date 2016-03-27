module.exports = do
  port: \9000 # backend port
  limit: '20mb'
  watch: false

  facebook:
    clientSecret: \00000000000000000000000000000000

  cookie:
    domain: null

  session:
    secret: \featureisameasurableproperty

  mail: do
    host: \box590.bluehost.com
    port: 465
    secure: true
    maxConnections: 5
    maxMessages: 10
    auth: {user: '', pass: ''}
