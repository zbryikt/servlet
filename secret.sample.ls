module.exports = do
  config: \localhost
  port: \9000 # backend port
  limit: '20mb'
  watch: true

  facebook:
    clientSecret: \----

  google:
    clientSecret: \----

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

  io-pg: do
    uri: "postgres://username:1234@localhost/dbname"
