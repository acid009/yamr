#### Yamr

Yamr is a chat application built with [nodejs](http://nodejs.org)
You can demo it by going to [yamr.net](http://yamr.net)

#### Installation

Yamr was built on node [v0.4.9](http://nodejs.org/dist/node-v0.4.9.tar.gz) (the version currently packaged with ubuntu
11.10), and requires [npm](http://npmjs.org), a [mysql](http://www.mysql.com) database, [sass](http://sass-lang.com), [coffeescript](http://jashkenas.github.com/coffee-script/) and [yuicompressor-2.4.7](http://developer.yahoo.com/yui/compressor/). The rest of the dependencies can be installed after cloning the repository and running

    npm install -d

Once set up, you'll want to edit src/config.coffee and run the following
commands (or set up a build script)

    coffee -o ./compiled/ -c src
    sass --update src/public/stylesheets:compiled/public/stylesheets
    cat compiled/public/javascripts/jquery-1.6.4.min.js > compiled/public/javascripts/all.js
    java -jar yuicompressor-2.4.7.jar compiled/public/javascripts/socket.io.js >> compiled/public/javascripts/all.js
    cat compiled/public/javascripts/jquery-ui-1.8.16.custom.min.js >> compiled/public/javascripts/all.js
    java -jar yuicompressor-2.4.7.jar compiled/public/javascripts/chat.js >> compiled/public/javascripts/all.js
    java -jar yuicompressor-2.4.7.jar compiled/public/javascripts/yamr.js >> compiled/public/javascripts/all.js
    java -jar yuicompressor-2.4.7.jar compiled/public/stylesheets/chat.css -o compiled/public/stylesheets/chat.css

Once everything compiles successfully, run the following to start in
development mode

    NODE_ENV=development node compiled/app

Or for production mode, just run

    node compiled/app

#### Nginx

Here is a sample nginx configuration

    upstream app {
      server 127.0.0.1:8000;
    }

    server {
      listen 80;
      server_name yamr.net;
      root /path/to/compiled/public;

      location / {
        index index.html;

        if (-f $request_filename) {
          break;
        }

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-NginX-Proxy true;
        proxy_pass http://app/;
        proxy_redirect off;
      }

      location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|txt)$ {
        expires max;
        access_log off;
      }
    }

#### SQL

Here is the SQL for creating the mysql database

    CREATE DATABASE `yamr` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

    CREATE TABLE IF NOT EXISTS guests (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `agent` varchar(255) DEFAULT NULL,
      `ip` char(15) DEFAULT NULL,
      `created` datetime DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TABLE IF NOT EXISTS `messages` (
      `id` int(10) NOT NULL AUTO_INCREMENT,
      `room_id` int(10) unsigned NOT NULL,
      `user_id` int(10) unsigned NOT NULL,
      `guest_id` int(10) unsigned NOT NULL,
      `message` varchar(255) NOT NULL,
      `created` datetime NOT NULL,
      PRIMARY KEY (`id`),
      KEY `room_id` (`room_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TABLE IF NOT EXISTS `rooms` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `name` varchar(255) NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;

    CREATE TABLE IF NOT EXISTS `users` (
      `id` int(10) NOT NULL AUTO_INCREMENT,
      `name` varchar(255) NOT NULL,
      `password` varchar(128) NOT NULL,
      `created` datetime NOT NULL,
      `ip` char(15) NOT NULL,
      `agent` varchar(255) NOT NULL,
      `headshot` int(10) unsigned NOT NULL DEFAULT '0',
      `last_login` date DEFAULT NULL,
      PRIMARY KEY (`id`),
      UNIQUE KEY `username` (`name`)
    ) ENGINE=InnoDB  DEFAULT CHARSET=utf8;
