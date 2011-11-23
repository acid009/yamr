module 'Yamr'
test 'Youtube links', ->
  # tests youtube links show the thumbnail preview
  v = '0fTD0mUT5qE'
  img = '<img src="http://i1.ytimg.com/vi/' + v + '/default.jpg" width="120" height="90" class="youtube" data-v="' + v + '"/>'

  str = 'http://www.youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

  str = 'https://www.youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

  str = 'https://youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

  str = 'http://youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

  str = 'www.youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

  str = 'youtube.com/watch?v=' + v + '&feature=feedrec_grec_index'
  equal chat.autoLink(str), img

test 'Regular Links', ->
  # tests links in text get hyperlinked
  str = 'http://www.example.com'
  linked = '<a href="' + str + '" target="_blank" rel="nofollow">' + str + '</a>'
  equal chat.autoLink(str), linked

  str = 'https://www.example.com'
  linked = '<a href="' + str + '" target="_blank" rel="nofollow">' + str + '</a>'
  equal chat.autoLink(str), linked

  str = 'http://example.com'
  linked = '<a href="' + str + '" target="_blank" rel="nofollow">' + str + '</a>'
  equal chat.autoLink(str), linked

  str = 'https://example.com'
  linked = '<a href="' + str + '" target="_blank" rel="nofollow">' + str + '</a>'
  equal chat.autoLink(str), linked

  str = 'www.example.com'
  linked = '<a href="http://' + str + '" target="_blank" rel="nofollow">' + str + '</a>'
  equal chat.autoLink(str), linked

test 'Email addresses', ->
  str = 'example@example.com'
  linked = '<a href="mailto:example@example.com">example@example.com</a>'
  equal chat.autoLink(str), linked

test 'Escape Html', ->
  equal chat.escapeHtml('<html>'), '&lt;html&gt;'
