template
========

a web template, for simple web service. it contains a simple webserver, watch daemon. It uses jade, sass and livescript to build a web page.


Usage
========

TBD

Configuration
========

by default, some javascript libraries are included. Config to use them or cdn by editing following code in index.jade:

    - var usecdn = false
    - var lib = { jquery: true, d3js: true, angular: true, bootstrap: false, semantic: true }
    - var assets = "/assets"

