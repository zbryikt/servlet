module.exports = do
  facebook:
    clientID: \1485497741698395
    clientSecret: \6753e6922de2c21538ca2b6a26bf09af

  gcs:
    projectId: \your-gcs-project-name
    keyFilename: \your-gcs-private-key-file

  mongodb:
    url: \mongodb://localhost/

  watch: false
  driver: \localfs

  test:
    session: false
    gcdspeed: false

  cookie:
    domain: null

  session-secret: \featureisameasurableproperty
  url: \http://your-domain/
  name: \your-project-name
  port: \9000 # backend port
  debug: true
  limit: '20mb'

  mail: do
    host: \box590.bluehost.com
    port: 465
    secure: true
    maxConnections: 5
    maxMessages: 10
    auth: {user: '', pass: ''}
