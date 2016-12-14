socket = socketCluster.connect()
socket.on 'error', (err) -> throw 'Socket error - ' + err
socket.on 'connect', -> console.log 'CONNECTED'

messageChannel = socket.subscribe('message.publish')
messageChannel.watch (data) ->
  dl = document.getElementById('messages')
  dt = document.createElement('dt')
  dt.textContent = data.username
  dl.appendChild dt
  dd = document.createElement('dd')
  
  dd.textContent = data.message if data.message?
  if data.image?
    img = document.createElement('img')
    img.src=data.image
    dd.appendChild img
  dl.appendChild obj for obj in [dt, dd]

class app
  constructor: ->
    dl = document.getElementById('messages')
    document.messageForm.message.addEventListener 'paste', @onPaste
    document.messageForm.addEventListener 'submit', @onSubmit
  onSubmit: (e) ->
    pasteImg = document.getElementById('paste-img')
    socket.emit 'message.send',
      Object.assign username: document.messageForm.username.value,
        # ternary
        if pasteImg?.src
        then image: pasteImg?.src 
        else message: document.messageForm.message.value
    pasteImg.remove() if pasteImg?
    e.preventDefault()
    false
  removeChildren: (obj) -> o.remove() for o in obj?.children
  pasteImage: (e) =>
    imageHolder = document.getElementById('imageholder')
    @removeChildren imageHolder
    img = document.createElement('img')
    img.setAttribute 'id', 'paste-img'
    img.src = e.target.result
    imageHolder.append img
  onPaste: (e) =>
    for clip in e.clipboardData.items when clip.kind is 'file' and clip.type.indexOf('image/') is 0
      reader = new FileReader()
      reader.onload = @pasteImage
      reader.readAsDataURL clip.getAsFile()
      e.preventDefault()
    false

document.addEventListener 'DOMContentLoaded', -> new app()
