require! <[fs path chokidar child_process]>

ls   = if fs.existsSync v=\node_modules/.bin/livescript => v else \livescript
jade = if fs.existsSync v=\node_modules/.bin/jade => v else \jade
sass = if fs.existsSync v=\node_modules/.bin/sass => v else \sass
cwd = path.resolve process.cwd!
cwd-re = new RegExp RegExp.escape "#cwd#{if cwd[* - 1]=='/' => "" else \/}"
if process.env.OS=="Windows_NT" => [jade,sass,ls] = [jade,sass,ls]map -> it.replace /\//g,\\\
log = (error, stdout, stderr) -> if "#{stdout}\n#{stderr}".trim! => console.log that

mkdir-recurse = ->
  if !fs.exists-sync(it) => 
    mkdir-recurse path.dirname it
    fs.mkdir-sync it

sass-tree = do
  down-hash: {}
  up-hash: {}
  parse: (filename) ->
    dir = path.dirname(filename)
    ret = fs.read-file-sync filename .toString!split \\n .map(-> /^ *@import (.+)/.exec it)filter(->it)map(->it.1)
    ret = ret.map -> path.join(dir, it.replace(/(\.sass)?$/, ".sass"))
    @down-hash[filename] = ret
    for it in ret => if not (filename in @up-hash.[][it]) => @up-hash.[][it].push filename
  find-root: (filename) ->
    work = [filename]
    ret = []
    while work.length > 0
      f = work.pop!
      if @up-hash.[][f].length == 0 => ret.push f
      else work ++= @up-hash[f]
    ret

ftype = ->
  switch
  | /\.ls$/.exec it => "ls"
  | /\.sass$/.exec it => "sass"
  | /\.jade$/.exec it => "jade"
  | otherwise => "other"

base = do
  ignore-list: [/^(.+\/)*?\.[^/]+$/]
  ignore-func: (f) -> @ignore-list.filter(-> it.exec f.replace(cwd-re, "")replace(/^\.\/+/, ""))length
  start: ->
    <[src src/ls src/sass static static/css static/js]>.map ->
      if !fs.exists-sync it => fs.mkdir-sync it
    watcher = chokidar.watch 'src', ignored: (~> @ignore-func it), persistent: true
      .on \add, @watch-handler
      .on \change, @watch-handler
  watch-handler: ->
    # TODO asynchronous build for reduce redundant building
    src = if it.0 != \/ => path.join(cwd,it) else it
    src = src.replace path.join(cwd,\/), ""
    [type,cmd,dess] = [ftype(src), "",[]]
    if type == \ls => 
      des = src.replace \src/ls, \static/js
      des = des.replace /\.ls$/, ".js"
      cmd = "#ls -cbp #src > #des"
      dess.push des
    else if type == \sass => 
      sass-tree.parse src
      srcs = sass-tree.find-root src
      cmd = srcs.map (src) ->
        des = src.replace \src/sass, \static/css
        des = des.replace /\.sass/, ".css"
        dess.push des
        "#sass #src #des"
      cmd = cmd.join \;
    else => return
    if !cmd => return
    if dess.length => for dir in dess.map(->path.dirname it) =>
      if !fs.exists-sync dir => mkdir-recurse dir
    console.log "[BUILD] #cmd"
    child_process.exec cmd, log

module.exports = watcher
