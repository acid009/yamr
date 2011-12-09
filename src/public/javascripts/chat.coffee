window.chat = {
  enabled: true
  roomHeight: 0
  socket: false
  reconnect: false
  idle: 0
  idleTimer: false
  typing: 0
  tipsIndex: 0

  scrollToBottom: (id) ->
    id = $.trim id
    document.getElementById(id).scrollTop = document.getElementById(id).scrollHeight

  enable: ->
    chat.enabled = true
    $('#body').removeClass 'faded'
    $('#spinner').hide()
    $('#message').attr 'disabled', false
    $('#message').focus()

  disable: ->
    w = $('#body').width()
    h = $('#body').height()

    $('#spinner').css({
      position: 'absolute'
      left: (w/2) - 25
      top: (h/2) - 25
    }).show()

    $('#body').addClass 'faded'
    $('#spinner').show()
    $('#message').attr 'disabled', true

  resize: ->
    w = $('#body').width()
    h = $('#body').height()
    chatHeight = $('#chat').height()
    chat.roomHeight = h - chatHeight

    $('#room').css('width', w - 210)
    $('#room').css('bottom', chatHeight)

    chat.resizeMessageInput()
    chat.scrollToBottom('room')

  resizeMessageInput: ->
    chatWidth = $('#chat div').width()
    chatWidth -= ($('#chat div form span').width() + 12)
    chatWidth -= ($('#info').width() + 12)
    $('#message').css('width', chatWidth)

  showInfo: (info) ->
    $('#info').html info
    chat.resizeMessageInput()

  playYoutube: (obj) ->
    scrollBottom = chat.isScrolledBottom('room')
    v = $(obj).data('v')
    $(obj).wrap('<span>').parent().html('<iframe width="281" height="200" src="http://www.youtube.com/embed/' + v + '?autoplay=1" frameborder="0"></iframe>')
    if (scrollBottom)
      chat.scrollToBottom('room')

  autoLink: (t) ->
    t = ' ' + t
    regexp = new RegExp '(http://|https://)?(www.)?youtube.com/watch\\?v=([\-_a-z0-9]+)\\S*', 'i'
    t = t.replace regexp, '<img src="http://i1.ytimg.com/vi/$3/default.jpg" width="120" height="90" class="youtube" data-v="$3"/>'

    regexp = new RegExp '(^|[\\n ])([\\w]+?://[\\w]+[^ \\"\\n\\r\\t<]*)', 'i'
    t = t.replace regexp, '$1<a href="$2" target="_blank" rel="nofollow">$2</a>'

    regexp = new RegExp '(^|[\\n ])(www\\.[^ \\"\\t\\n\\r<]*)', 'i'
    t = t.replace regexp, '$1<a href="http://$2" target="_blank" rel="nofollow">$2</a>'

    regexp = new RegExp '(^|[\\n ])([a-z0-9&\\-_\\.]+?)@([\\w\\-]+\\.([\\w\\-\\.]+\\.)*[\\w]+)', 'i'
    t = t.replace regexp, '$1<a href="mailto:$2@$3">$2@$3</a>'

    $.trim t

  escapeHtml: (t) ->
    r1 = new RegExp '<', 'g'
    r2 = new RegExp '>', 'g'
    t.replace(r1, '&lt;').replace(r2, '&gt;')

  signup: (str) ->
    space = str.indexOf(' ')

    if space == -1
      space = str.length

    chat.showInfo '<img src="/images/spinner.gif" width="14" height="14"/>'
    args = {
      username: str.substr 0, space
      password: str.substr space + 1
    }
    $.ajax({
      url: '/signup'
      type: 'POST'
      data: args
      success: (resp) ->
        if resp
          chat.showInfo resp
        else
          location.href = location.href
    })

  login: (str) ->
    space = str.indexOf(' ')

    if space == -1
      space = str.length

    chat.showInfo '<img src="/images/spinner.gif" width="14" height="14"/>'
    args = {
      username: str.substr 0, space
      password: str.substr space + 1
    }

    $.ajax({
      url: '/login'
      type: 'POST'
      data: args
      success: (resp) ->
        if resp
          chat.showInfo resp
        else
          location.href = location.href
    })

  headshot: (str) ->
    form = $('form.headshot-form').clone()
      .removeClass().attr('id', 'headshot-form')
      .wrap('<div>').parent().html()
    chat.showInfo form

  save: ->
    message = $.trim($('#message').val())
    time = chat.getNow()

    $('#message').val '' # clear ASAP to avoid double clicks

    if !message
      return false

    if message == '/clear'
      chat.clear()
      chat.showInfo ''
      return false

    if message.substr(0, 6) == '/login'
      chat.login message.substr(7)
      return false

    if message.substr(0, 7) == '/signup'
      chat.signup message.substr(8)
      return false

    if message.substr(0, 9) == '/headshot'
      chat.headshot message.substr(10)
      return false
   
    if message == '/logout'
      chat.logout()
      return false

    chat.socket.json.send { message: message }

    chat.setIdle()

    return false

  getNow: ->
    chat.formatTime()

  formatTime: (date) ->
    if (date instanceof Date) == false
      date = new Date()

    h = date.getHours()
    i = date.getMinutes()

    if i < 10
      i = '0' + i

    if h > 12
        time = (h-12) + ':' + i
    else if h == 0
        time = '12:' + i
    else
        time = h + ':' + i

    time = h >= 12 ? time + ' pm' : time + ' am'

    time

  clear: ->
    $('#room').html ''
    $('#message').val ''

  autoClear: ->
    if $('div.message').length <= 50
      return false

    $('div.message:first').remove()

  showJoin: (obj) ->
    user = obj.user
    imgId = 'u' + user.name

    if user.headshot > 0
      headshot = '/headshots/' + user.name + '.jpg?' + user.headshot
    else
      headshot = '/images/no_photo.gif'

    if typeof $('#' + imgId).data('count') == 'undefined'
      html = '<div id="' + imgId + '" data-count="1">'
      html += '<img src="' + headshot + '" class="headshot" title="' + user.name + ' is online"/>'
      html += user.name
      html += '</div>'
      $('#online').append html

      if user.typing
        $('div#' + imgId + ' img').addClass('typing').attr('title', user.name + ' is typing')

      if user.idle
        $('div#' + imgId + ' img').addClass('idle').attr('title', user.name + ' is idle')
    else
      # if user logs in with a new tab, increment the count
      # so we know not to remove the user when the tab closes
      # if the count is greater than 1
      $('#' + imgId).data('count', parseInt($('#' + imgId).data('count')) + 1);

    if user.name == chat.getCurrentUser()
      if user.name.substr(0, 5) == 'Guest'
        commands = [
          { value: '/clear', label: '/clear', desc: '- clear the screen' },
        ]
        if obj.db
          commands.push(
            { value: '/login ', label: '/login [username] [password]', desc: '' },
            { value: '/signup ', label: '/signup [username] [password]', desc: '' },
          )
      else
        commands = [
          { value: '/clear', label: '/clear', desc: '- clear the screen' },
        ]
        if obj.db
          commands.push(
            { value: '/headshot', label: '/headshot', desc: '- upload a headshot' },
          )
        commands.push(
          { value: '/logout', label: '/logout', desc: '' }
        )
      $('#message').autocomplete({
        source: commands
        position: { my: 'left bottom', at: 'left top' }
        collision: 'flip'
        focus: (eventu, ui) ->
          $('#message').val ui.item.value
          false
        select: (event, ui) ->
          $('#message').val ui.item.value
          false

        search: (event, ui) ->
          str = event.target.value
          if str.substr(0, 1) == '/' or str == ''
            return true
          else
           return false
      }).data('autocomplete')._renderItem = (ul, item) ->
        $('<li></li>').data('item.autocomplete', item)
          .append('<a>' + item.label + ' <small>' + item.desc + '</small></a>')
          .appendTo(ul)

  showMessage: (obj) ->
    if parseInt($('#room').attr('data-v')) != parseInt(obj.user.version)
      if !chat.isTyping()
        location.href = location.href
        return

    lastUser = $('#room img.headshot:last')
    scrolledBottom = chat.isScrolledBottom('room')

    if obj.user.headshot > 0
      headshot = '/headshots/' + obj.user.name + '.jpg?' + obj.user.headshot
    else
      headshot = '/images/no_photo.gif'

    if 'created' of obj
      # if the object has a "created" attribute,
      # then this is from the initial join and
      # we want to use the date from the db as well
      # as force the room to scroll to the bottom
      time = obj.created
      scrolledBottom = true
    else
      date = new Date()
      h = date.getHours()
      i = date.getMinutes()
      i = '0' + i if i < 10
      if h > 12
        time = (h - 12) + ':' + i
      else if h == 0
        time = '12:' + i
      else
        time = h + ':' + i

      if h >= 12
        time = time + ' pm'
      else
        time = time + ' am'

    if lastUser.attr('title') == obj.user.name
      html = '<div>'
      html += chat.autoLink(chat.escapeHtml(obj.message))
      html += '<span class="time">' + time + '</span>'
      html += '</div>'
      lastUser.parent().children('div').append html
    else
      html = '<div class="message">'
      html += '<img src="' + headshot + '" class="headshot" title="' + obj.user.name + '"/>'
      html += '<div>'
      html += '<strong>' + obj.user.name + ':</strong><br/>'
      html += '<div>'
      html += '<div>'
      html += chat.autoLink(chat.escapeHtml(obj.message))
      html += '<span class="time">' + time + '</span>'
      html += '</div>'
      html += '</div>'
      html += '</div>'
      $('#room').append html

    if chat.roomHeight && $('#room').height() > chat.roomHeight
      $('#room').css 'height', chat.roomHeight
      chat.roomHeight = 0

    if scrolledBottom
      chat.scrollToBottom 'room'

    user = chat.getCurrentUser()
    if user != obj.user.name
      document.title = obj.user.name + ' says...'

    chat.autoClear()

  getCurrentUser: ->
    if !chat.user
      chat.user = $('#chat form span').html().split(':')[0]
    chat.user

  isScrolledBottom: (id) ->
    currentHeight = 0
    scrollHeight = document.getElementById(id).scrollHeight
    offsetHeight = document.getElementById(id).offsetHeight
    scrollTop = document.getElementById(id).scrollTop
    pixelHeight = document.getElementById(id).style.pixelHeight

    if typeof pixelHeight == 'undefined'
      pixelHeight = 0

    if scrollHeight > 0
      currentHeight = scrollHeight
    else if offsetHeight > 0
      currentHeight = offsetHeight

    if pixelHeight > 0
      offsetHeight = pixelHeight

    (currentHeight - scrollTop - offsetHeight < 50)

  setIdle: ->
    d = new Date()
    $('#idle').val d.getTime()

    if chat.idleTimer
      clearTimeout chat.idleTimer

    chat.isIdle()

  isIdle: ->
    d = new Date()
    i = $('#idle').val()
    idle = 0

    if i == ''
      i = d.getTime()

    # 5 minutes
    if (d.getTime() - i) >= 30000
      idle = 1

    if idle && idle != chat.idle
      chat.idle = idle
      chat.socket.json.send { idle: chat.idle }
    else if !idle && idle != chat.idle
      chat.idle = idle
      chat.socket.json.send { idle: chat.idle }

    chat.idleTimer = setTimeout chat.isIdle, 60000

  showIdle: (obj) ->
    if obj.idle
      $('#u' + obj.user.name + ' img').addClass('idle').attr('title', obj.user.name + ' is idle')
    else
      $('#u' + obj.user.name + ' img').removeClass('idle').attr('title', obj.user.name + ' is online')

  showTyping: (obj) ->
    if obj.typing
      $('#u' + obj.user.name + ' img').addClass('typing').attr('title', obj.user.name + ' is typing')
    else
      $('#u' + obj.user.name + ' img').removeClass('typing').attr('title', obj.user.name + ' is online')

  setTyping: ->
    typing = chat.isTyping()

    if typing && typing != chat.typing
      chat.typing = typing
      chat.socket.json.send { typing: chat.typing }
    else if !typing && typing != chat.typing
      chat.typing = typing
      chat.socket.json.send { typing: chat.typing }

  isTyping: ->
    message = $('#message').val()
    if message && message.substr(0, 1) != '/'
      return 1
    else
      return 0
    
  hiddenFrameLoad: ->
    if frames['hiddenIframe'].document == null
      chat.showInfo 'error adding headshot'
      return false

    iframe = frames['hiddenIframe'].document.body.innerHTML

    if iframe.indexOf('/headshots/') != -1
      chat.showInfo ''
      user = $('#chat form span').html().split(':')[0]
      $('#u' + user + ' img').attr('src', iframe)
    else
      chat.showInfo 'error adding headshot'
       
  logout: ->
    $.post '/logout', {}, ->
      location.href = '/'

  handleClick: (event) ->
    if !chat.enabled
      return false
    
    target = $(event.target)

    if target.is 'img.youtube'
      chat.playYoutube target
    else if target.is 'span.prevTip'
      chat.tipsIndex = chat.tipsIndex - 2
      chat.showTip chat.tipsIndex--
    else if target.is 'span.nextTip'
      chat.showTip chat.tipsIndex++

  showLogout: (user) ->
    obj = $('#u' + user.name)
    count = parseInt obj.data('count')
    if count > 1
      obj.data 'count', count - 1
    else
      offset = obj.offset()
      obj.fadeOut 'fast', ->
        $(this).remove()

      $('<div class="poof">').css({
        left: offset.left + 5
        top: offset.top + 5
      }).appendTo('body').show()

      chat.animatePoof()

  animatePoof: ->
    bgTop = 0
    frames = 5
    frameSize = 32
    frameRate = 80

    for i in [1..frames]
      $('div.poof').animate({
        backgroundPosition: '0' + (bgTop - frameSize)
      }, frameRate)
      bgTop -= frameSize

    setTimeout("$('div.poof').remove()", frames + frameRate)

  showTip: (i) ->
    tipCount = $('#tips div').length

    if i >= tipCount
      i = 0
    else if i < 0
      i = tipCount - 1

    $('span.nextTip').remove()
    $('span.prevTip').remove()
    if i < tipCount - 1
      $('#tips div').prepend '<span class="nextTip">&rarr;</span>'
    if i >= tipCount - 1
      $('#tips div').prepend '<span class="prevTip">&larr;</span>'

    $('#tips div').hide()
    $('#tips div:eq(' + i + ')').fadeIn()

    chat.tipsIndex = ++i

  handleObj: (obj) ->
    if 'message' of obj
      chat.showMessage obj
    else if 'join' of obj
      chat.showJoin obj
    else if 'typing' of obj
      chat.showTyping obj
    else if 'idle' of obj
      chat.showIdle obj
    else if 'logout' of obj
      chat.showLogout obj.user

  connect: ->
    chat.socket = io.connect(null, { port: 8000 })

    chat.socket.on 'connect', ->
      if chat.reconnect
        clearInterval chat.reconnect

      chat.socket.json.send { join: 1 }
      chat.enable()

    chat.socket.on 'message', (obj) ->
      if obj.length != undefined
        for o in obj
          chat.handleObj o
      else
        chat.handleObj obj

    chat.socket.on 'disconnect', ->
      chat.disable()
      chat.reconnect = setInterval 'chat.socket.connect()', 10000
}
