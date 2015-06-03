require! <[mongodb bluebird]>

main = (driver) ->
  {db,ds} = driver{db,ds}
  col = {}

  OID = mongodb.ObjectID
  get-collection = (name, cb) -> 
    if !col[name] => return db.collection name, (e, ret) -> cb(col[name] = ret)
    else cb(col[name])

  return store = do
    read: (prefix, key) -> new bluebird (res, rej) -> get-collection prefix, (root) ->
      try
        root.findOne {_id: OID key}, (e,b) -> res b
      catch => res null
    write: (prefix, key, data) -> new bluebird (res, rej) -> get-collection prefix, (root) ->
      if key => 
        (e,r,b) <- root.update {_id: OID key},  {$set: data}, {upsert: true, w:1}
        return res b
      else 
        if data._id => delete data._id
        (e,b) <- root.insert data, {w:1}
        b = b.0
        b.key = b._id
        (e,r,c) <- root.update {_id: OID b._id}, {$set: {key: OID b._id}}, {w: 1}
        return res b

    delete: (prefix, key) -> new bluebird (res, rej) ->  get-collection prefix, (root) ->
      root.remove {_id: OID key} -> res!

    list: (prefix, field, values) -> new bluebird (res, rej) -> get-collection prefix, (root) ->
      query = {}
      if typeof(values) == typeof([]) and values.length =>
        if field == 'key' => values := values.map(->OID it)
        query[field] = { $in: values }
      else query[field] = values
      cursor = root.find(query).toArray (e,b) -> res b

module.exports = main
