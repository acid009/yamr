chat.disable()
chat.resize()
chat.connect()
chat.setIdle()

$('#chat form').submit ->
  chat.save()
  false

$('#message').keyup ->
  chat.setTyping()

document.title = $('#room-name').val()

window.onresize = ->
  chat.resize()

document.onmousemove = ->
  chat.setIdle()
  document.title = $('#room-name').val()

document.onkeypress = ->
  chat.setIdle()
  document.title = $('#room-name').val()

$('div.message div div').live 'mouseover mouseout', (e) ->
  if e.type == 'mouseout'
    $(this).find('span.time').hide()
  else if e.type == 'mouseover'
    $(this).find('span.time').show()

$('#hiddenIframe').load chat.hiddenFrameLoad
$('input.headshot-file').live 'change', ->
  $('form#headshot-form').submit()
  chat.showInfo '<img src="/images/spinner.gif" width="14" height="14"/>'

chat.showTip 0

$(document).click chat.handleClick
