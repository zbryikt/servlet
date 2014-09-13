template
========

a web template, for simple web service. it contains a simple webserver, watch daemon. It uses jade, sass and livescript to build a web page.


Usage
========

in the repo root directory, run following commands to initialize and start the server:

    npm install
    mkdir db && mongod --dbpath db &
    lsc server &
    nginx -c $(pwd)/nginx.config

You can now access http://localhost that shows a big "hello world" on your screen.

it's optional to run nginx which serves files through http://localhost.  Wihtout nginx you can still work with http://localhost:9000 which is served by 'lsc server'. the backend server is built with a simple login (by email and facebook) interface and have mongodb ready to serve.

File Structure
========

* db - for mongodb database
* view - for backend served template. check view/index.jade for your hello world at http://localhost/.
* src - livescript and sass code
* static - all built file and static files. keep static/css and static/js clean without modify them.
* static/assets - all external libraries
* backend.ls - vital mechanisms are put here to keep server.ls simple, including:
  * login, both email and facebook
  * email transport
  * mongodb 
  * basic router: api (/d), user (/u)
* server.ls - extend your web server from this file.

Configuration
========

by default, some javascript libraries are included. Config to use them or cdn by editing following code in view/index.jade:

    - var usecdn = false
    - var lib = { jquery: true, d3js: true, angular: true, bootstrap: false, semantic: true }
    - var assets = "/assets"

To config your backend, check sample configuration in backend.ls. It's a base config and can be overwritten by the one provided in server.ls. Please keep backend.ls clean and patch it in server.ls. Explanation as follows:


    session-secret: < a random string for keeping session secure >
    url: < base url of your domain >
    name: < project name, use in mongodb >
    mongodbUrl: < mongodb server url >
    port: < backend server port of listen >
    facebook:
      clientID: < app id of your facebook >
      clientSecret: < secret of your facebook app >
    mail: do
      host: < outgoing mail server hostname >
      port: < outgoing mail server port >
      secure: < true or false, use ssl or not >
      auth: do
        user: < mail server login username >
        pass: < mail server login user password >
      maxConnections: 5
      maxMessages: 10
