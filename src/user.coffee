config = require './config'
crypto = require 'crypto'
base64 = require './base64'
mysql  = require 'mysql'

class User
  updateHeadshotVersion: (req, res) ->
    this.headshot++
    User.set req, res, this

    if config.db
      db = mysql.createClient config.db
      sql = 'UPDATE users SET headshot = headshot + 1 WHERE id = ?'
      db.query sql, [this.id]

User.getByKey = (key) ->
  parts = base64.decode(unescape(key)).split('-')
  sig = parts[0]
  time = parts[1]
  value = parts[2]

  if sig == crypto.createHash('sha1').update(config.secret + time + value).digest('hex')
    parts = value.split '|'
    if parts.length == 5
      user = new User()
      user.id = parts[0]
      user.name = parts[1]
      user.version = parts[2]
      user.headshot = parts[3]
      user.room_id = parts[4]
      return user
  false

User.get = (req, res, room, cb) ->
  user = User.getByKey req.cookies.key
  if user
    return cb null, user

  # if the database is enabled, use that for tracking guests
  if config.db
    db = mysql.createClient config.db

    agent = db.escape req.header('user-agent', '')
    ip = db.escape req.connection.remoteAddress
    sql = 'INSERT INTO guests (ip, agent, created) VALUES (' + ip + ', ' + agent + ', NOW())'
    db.query sql, (err, info) ->
      if err
        cb err, null
      else
        id = info.insertId
        user = new User()
        user.id = id
        user.name = 'Guest' + id
        user.room_id = room.id
        user.headshot = 0
        user.version = config.version
        User.set req, res, user
        cb null, user
  else
    id = new Date().getTime()
    user = new User()
    user.id = id
    user.name = 'Guest' + id
    user.room_id = room.id
    user.headshot = 0
    user.version = config.version
    User.set req, res, user
    cb null, user


User.set = (req, res, user) ->
  time = new Date().getTime()
  str = user.id + '|' + user.name + '|' + user.version + '|' + user.headshot + '|' + user.room_id
  sig = crypto.createHash('sha1').update(config.secret + time + str).digest('hex')
  res.cookie 'key', base64.encode(sig + '-' + time + '-' + str), { maxAge: 1000 * 60 * 60 * 24 * 365 }

module.exports = User
