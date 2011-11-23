exports.port = 8000

exports.db = {
  host: 'localhost'
  user: 'root'
  password: ''
  database: 'yamr'
  port: 3306
}
# You can set exports.db to false,
# if you don't want to use a database.
# This will disable signups/logins and
# saving messages
# exports.db = false

# bump this when you need to force-refresh
# the site for logged in users
exports.version = 10

exports.secret = 'change me'

exports.plugins = [
  'join',
  'save_message_to_database'
]
