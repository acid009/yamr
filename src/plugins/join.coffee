config = require '../config'
mysql  = require 'mysql'

exports.before_message = (obj) ->
  if 'join' of obj.data
    obj.socket.join(obj.data.user.room_id)
    clients = obj.io.sockets.clients(obj.data.user.room_id)

    joins = []
    for client in clients
      for k in Object.keys(client.namespace.manager.handshaken)
        u = client.namespace.manager.handshaken[k].user
        if obj.data.user.name != u.name and obj.data.user.room_id == u.room_id
          joins.push { 'join': 1, 'user': u }
    obj.io.sockets.sockets[obj.socket.id].json.send joins

    # if we're saving messages to the database, then when users join
    # we show the last 50 messages
    if config.db and 'save_message_to_database' in config.plugins
      room_id = obj.data.user.room_id

      db = mysql.createClient config.db
      sql = 'SELECT m.message, m.user_id, m.guest_id, m.room_id, m.created, u.name, u.headshot '
      sql += 'FROM messages m '
      sql += 'LEFT JOIN users u ON m.user_id = u.id '
      sql += 'WHERE m.room_id = ? '
      sql += 'ORDER BY m.id DESC '
      sql += 'LIMIT 50'
      db.query sql, [room_id], (err, results) ->
        if err
          console.error err
        else
          if results.length >= 1
            messages = []
            for row in results
              if parseInt(row.guest_id) > 0
                id = row.guest_id
                name = 'Guest' + row.guest_id
              else
                id = row.user_id
                name = row.name

              date = new Date()
              hours = row.created.getHours()
              if hours > 12
                hours -= 12
                am = 'pm'
              else
                am = 'am'
              hours = 12 if hours == 0

              if date.toDateString() == row.created.toDateString()
                created = hours + ':' + zeroPad(row.created.getMinutes(), 2) + ' ' + am + ' EDT'
              else if date.getFullYear() == row.created.getFullYear()
                created = (row.created.getMonth() + 1) + '/' + row.created.getDate() + ' @ ' + hours + ':' + zeroPad(row.created.getMinutes(), 2) + ' ' + am + ' EDT'
              else
                created = (row.created.getMonth() + 1) + '/' + row.created.getDate() + '/' + row.created.getFullYear() + ' @ ' + hours + ':' + zeroPad(row.created.getMinutes(), 2) + ' ' + am + ' EDT'

              messages.unshift {
                message: row.message
                created: created
                user: {
                  id: id
                  name: name
                  headshot: row.headshot
                  version: config.version
                }
              }

            obj.io.sockets.sockets[obj.socket.id].json.send messages
        db.end()

zeroPad = (num, count) ->
  num = num.toString()
  while num.length < count
    num = '0' + num
  num
