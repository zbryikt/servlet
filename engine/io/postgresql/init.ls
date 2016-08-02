require! <[../../../secret ../postgresql pg bluebird]>

init-sessions-table = """create table if not exists sessions (
  key text not null unique primary key,
  detail jsonb
)"""

init-users-table = """create table if not exists users (
  key serial primary key,
  username text constraint nlen check (char_length(username) <= 100),
  password text constraint pwlen check (char_length(password) <= 100),
  usepasswd boolean,
  displayname text, constraint displaynamelength check (char_length(displayname) <= 100),
  description text,
  datasize int,
  createdtime timestamp,
  lastactive timestamp,
  public_email boolean,
  avatar text,
  detail jsonb
)"""

client = new pg.Client secret.io-pg.uri
(e) <- client.connect
if e => return console.log e
console.log "connected"

query = (q) -> new bluebird (res, rej) ->
  (e,r) <- client.query q, _
  if e => rej e
  res r

query init-users-table
  .then -> query init-sessions-table
  .then ->
    console.log "done."
    client.end!
  .catch -> [console.log(it), client.end!]
