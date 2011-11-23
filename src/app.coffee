config      = require './config'
express     = require 'express'
io          = require 'socket.io'
connect     = require 'connect'
mysql       = require 'mysql'
form        = require 'connect-form'
User        = require './user'
Room        = require './room'

plugins = []
for plugin in config.plugins
  plugins.push require './plugins/' + plugin

app = express.createServer(
  form keepExtensions: true
)

app.configure ->
  app.use express.cookieParser()
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'

app.configure 'development', ->
  app.use express.static __dirname + '/public'
  app.use express.errorHandler dumpExceptions: true, showStack: true
  app.use express.bodyParser()

app.listen config.port

io = io.listen app

app.get '/:room?', (req, res) ->
  Room.get req.params.room, (err, room) ->
    User.get req, res, room, (err, user) ->
      if err
        console.error err
        return res.render 'error', { layout: false }
      else
        # if a user loads up a different room, we need to reset the cookie
        # to the correct room id
        if room.id != user.room_id
          user.room_id = room.id
          User.set req, res, user

        return res.render 'index', { user: user, room: room, version: config.version, layout: false }

app.post '/upload', (req, res, next) ->
  exec = require('child_process').exec

  # https://github.com/visionmedia/express/blob/master/examples/multipart/app.js
  req.form.complete (err, fields, files) ->
    body = ''
    if err
      console.error 'err1: ' + err
      res.send ''
    else
      user = User.getByKey req.cookies.key
      headshot_path = __dirname + '/public/headshots/' + user.name + '.jpg'
      exec("convert '" + files.headshot.path + "' '" + headshot_path + "'", (error, stdout, stderr) ->
        if error
          console.log 'error with uploaded headshot: ' + error
          res.send ''
        else
          exec("convert -scale '40x40' '" + headshot_path + "' '" + headshot_path + "'", (error, stdout, stderr) ->
            if error
              console.log 'error converting headshot: ' + error
              res.send ''
            else
              user.updateHeadshotVersion req, res
              res.send '<body>/headshots/' + user.name + '.jpg?' + user.headshot.toString() + '</body>'
          )
      )


app.post '/signup', (req, res) ->
  crypto = require 'crypto'
  base64 = require './base64'

  try
    name = req.body.username.replace(/[^a-zA-Z0-9]/, '').toLowerCase()
    password = req.body.password
  catch err
    name = ''
    password = ''

  if !name
    res.send 'you should enter a username'
  else if name.substr(0, 5) == 'guest'
    res.send '"Guest" usernames not allowed'
  else if !password
    res.send 'you should enter a password'
  else
    db = mysql.createClient config.db
    safeName = db.escape name
    db.query 'SELECT id FROM users WHERE name = ' + safeName, (err, results, fields) ->
      if results.length >= 1
        res.send 'username already exists'
      else
        agent = db.escape req.header('user-agent', '')
        ip = db.escape req.connection.remoteAddress
        shasum = crypto.createHash 'sha1'
        shasum.update password
        safePassword = shasum.digest 'hex'
        sql = 'INSERT INTO users (name, password, created, ip, agent, last_login) '
        sql += 'VALUES (' + safeName + ', "' + safePassword + '", NOW(), ' + ip + ', ' + agent + ', CURDATE())'
        db.query sql, (err, info) ->
          id = info.insertId
          oldUser = User.getByKey req.cookies.key
          user = new User()
          user.id = id
          user.name = name
          user.room_id = oldUser.room_id
          user.headshot = 0
          user.version = config.version
          User.set req, res, user

          res.send ''

app.post '/login', (req, res) ->
  crypto = require 'crypto'
  base64 = require './base64'

  try
    name = req.body.username
    password = req.body.password
  catch err
    name = ''
    password = ''

  if !name || !password
    res.send 'invalid login'
  else
    db = mysql.createClient config.db
    sql = 'SELECT id, password, headshot FROM users WHERE name = ?'
    db.query sql, [name], (err, results) ->
      if results.length >= 1
        row = results[0]
        shasum = crypto.createHash 'sha1'
        shasum.update password
        safePassword = shasum.digest 'hex'
        if safePassword == row.password
          oldUser = User.getByKey req.cookies.key
          user = new User()
          user.id = row.id
          user.name = name
          user.room_id = oldUser.room_id
          user.headshot = row.headshot
          user.version = config.version
          User.set req, res, user
          res.send ''
        else
          res.send 'invalid login'
      else
        res.send 'invalid login'

app.post '/logout', (req, res) ->
  res.clearCookie 'key'
  res.send ''

io.set 'authorization', (data, accept) ->
  if data.headers.cookie
    data.cookie = connect.utils.parseCookie data.headers.cookie
    data.user = User.getByKey data.cookie['key']
    accept null, true
  else
    accept 'No cookie transmitted', false

io.sockets.on 'connection', (socket) ->
  user = socket.handshake.user

  socket.on 'message', (data) ->
    # forces user to be passed with every message
    data['user'] = user

    # we pass whether or not the database is enabled
    # so the client-side JS knows if it should show or hide
    # certain commands
    data['db'] = config.db != false

    for plugin in plugins
      if 'before_message' of plugin
        plugin.before_message { io: io, socket: socket, data: data }

    if 'message' of data and data.message.substr(0, 1) == '/'
      # don't send commands
    else
      io.sockets.in(user.room_id).json.send data

    for plugin in plugins
      if 'after_message' of plugin
        plugin.after_message { io: io, socket: socket, data: data }

  socket.on 'disconnect', ->
    io.sockets.in(user.room_id).json.send { 'logout': 1, 'user': user }

  socket.on 'error', (err) ->
    console.error err
