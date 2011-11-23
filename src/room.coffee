config = require './config'
mysql  = require 'mysql'

class Room

Room.get = (room, cb) ->
  room = 'lobby' if !room

  if !config.db
    return cb null, { id: 0, name: room }

  db = mysql.createClient config.db
  sql = 'SELECT id, name FROM rooms WHERE name = ?'
  db.query sql, [room], (err, results) ->
    if err
      return cb err, {}

    if results.length >= 1
      cb null, {
        id: results[0].id
        name: room
      }
    else
      sql = 'INSERT INTO rooms (name) VALUES (?)'
      db.query sql, [room], (err, info) ->
        if err
          return cb err, {}

        cb null, {
          id: info.insertId
          name: room
        }

Room.set = (req, res, user) ->
  time = new Date().getTime()
  str = user.id + '|' + user.name + '|' + user.version + '|' + user.headshot + '|' + user.room_id
  sig = crypto.createHash('sha1').update(config.secret + time + str).digest('hex')
  res.cookie 'key', base64.encode(sig + '-' + time + '-' + str), { maxAge: 1000 * 60 * 60 * 24 * 365 }

  req.session.user = user

module.exports = Room
