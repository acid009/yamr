config = require '../config'
mysql  = require 'mysql'

exports.after_message = (obj) ->
  if 'message' of obj.data and obj.data.message.substr(0, 1) != '/'
    user_id = 0
    guest_id = 0
    message = obj.data.message
    room_id = obj.data.user.room_id

    if obj.data.user.name.substr(0, 5) == 'Guest'
      guest_id = parseInt(obj.data.user.id)
    else
      user_id = parseInt(obj.data.user.id)

    db = mysql.createClient config.db

    sql = 'INSERT INTO messages (room_id, user_id, guest_id, message, created) '
    sql += 'VALUES (?, ?, ?, ?, NOW())'
    db.query sql, [room_id, user_id, guest_id, message], (err, info) ->
      if err
        console.error err
      db.end()
