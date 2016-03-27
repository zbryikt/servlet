require! <[express]>
require! <[./secret ./engine ./engine/aux ./engine/share/config ./api/]>
require! <[./engine/io/localfs]>

config = aux.merge-config config, secret

lfs = new localfs!
<- lfs.init!then

<- engine.init config, lfs.authio .then
api engine
engine.start!
