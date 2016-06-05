async = require 'async'
W3CWebSocket = require('websocket').w3cwebsocket

getToken = (username, password) ->
  data =
    "login": username,
    "pass": password,
    "app": "desktop"
  request = new XMLHttpRequest()
  request.open "POST", "https://api.hitbox.tv/auth/token", false
  data = JSON.stringify(data)
  request.send data
  if request.status is 200
    return JSON.parse(request.response).authToken
  else
    console.log request.status,request.statusText
    return [request.status,request.statusText]

isUser = (username) ->
  request = new XMLHttpRequest()
  request.open "GET", "https://api.hitbox.tv/user/#{username}", false
  request.send
  if request.status is 200
    return true
  else
    return false

getWSServers = (callback) ->
  request = new XMLHttpRequest()
  request.open "GET", "https://api.hitbox.tv/chat/servers", false
  request.send null
  if request.status is 200
    serverslist = null;
    servers = JSON.parse request.responseText
    servers = async.map(servers, (i, cb) ->
      $.get new String().concat("http://",i.server_ip,"/socket.io/1/"), (data, status) ->
        if status is "success"
          txt = data.split(":")[0]
          server_ip = new String().concat i.server_ip, "/socket.io/1/websocket/"
          add = new String().concat("ws://",server_ip,txt)
          cb null, add
    ,(err, results) ->
      callback null, results
      return
    )
    return null
  else
    return error

getConnection = (nick, channel, token, cb) ->
  client = null
  getWSServers((err, list) ->
    test = false
    n = -1;
    async.until(()->
      n++
      return test || n>=list.length
    ,(callback)->
      client = new W3CWebSocket list[n]
      client.channel = channel
      client.userToken = token
      client.nick = nick
      client.onerror = () ->
        console.log "Connection Error"
        callback null
      client.onopen = () ->
        console.log('WebSocket Client Connected');
        test = true
        callback null, 2
      client.onclose = () ->
        console.log("Connection Closed")
        callback null
      client.onmessage = (e) ->
        if typeof e.data is "string"
          if e.data is "2::"
            client.send "2::"
      return
    ,(err, n)->
      if n is 2
        cb client
      return
    ))

W3CWebSocket.prototype.nickColor = "000000"
W3CWebSocket.prototype.nick = null
W3CWebSocket.prototype.channel = null
W3CWebSocket.prototype.authToken = null

W3CWebSocket.prototype.sendPackage = (pack) ->
  return sendPackage pack, this

sendPackage = (pack, client) ->
  unless typeof pack == "object"
    throw new TypeError("Wrong type of package. Expected: Object")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    name: "message"
    args: [pack]
  data = new String().concat("5:::", JSON.stringify(data))
  client.send(data)

W3CWebSocket.prototype.sendMessage = (msg) ->
  return sendMessage msg, this

sendMessage = (msg, client) ->
  unless typeof msg == "string"
    throw new TypeError("Wrong type of message. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method:"chatMsg"
    params:
      channel:client.channel.toLowerCase()
      name:client.nick
      nameColor:client.nickColor
      text:msg
  client.sendPackage data, client

W3CWebSocket.prototype.sendDirectMessage = (msg, usr) ->
  return sendDirectMessage msg, usr, this

sendDirectMessage = (msg, usr, client) ->
  unless typeof msg == "string"
    throw new TypeError("Wrong type of message. Expected: String")
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method:"directMsg"
    params:
      channel:client.channel.toLowerCase()
      from:client.nick
      to:usr
      nameColor:client.nickColor
      text:msg
  client.sendPackage data, client

W3CWebSocket.prototype.kickUser = (usr, time) ->
  return kickUser usr, time, this

kickUser = (usr, time, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless typeof time == "number"
    throw new TypeError("Wrong type of time. Expected: Number")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "kickUser"
    params:
      channel:client.channel.toLowerCase()
      name:usr
      token:client.userToken
      timeout:time.toString()
  sendPackage data, client

W3CWebSocket.prototype.banUser = (usr) ->
  return banUser usr, this

banUser = (usr, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "banUser"
    params:
      channel:client.channel
      name:usr
  sendPackage data, client

W3CWebSocket.prototype.banUserIP = (usr) ->
  return banUserIP usr, this

banUserIP = (usr, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "banUser"
    params:
      channel:client.channel
      name:usr
      token:client.authToken
      banIP:true
  sendPackage data, client

W3CWebSocket.prototype.unbanUser = (usr) ->
  return unbanUser usr, this

unbanUser = (usr, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "unbanUser"
    params:
      channel:client.channel
      name:usr
      token:client.authToken
  sendPackage data, client

W3CWebSocket.prototype.makeMod = (usr) ->
  return makeMod usr, this

makeMod = (usr, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "makeMod"
    params:
      channel:client.channel
      name:usr
      token:client.authToken
  sendPackage data, client

W3CWebSocket.prototype.removeMod = (usr) ->
  return removeMod usr, this

removeMod = (usr, client) ->
  unless typeof usr == "string"
    throw new TypeError("Wrong type of user. Expected: String")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "removeMod"
    params:
      channel:client.channel
      name:usr
      token:client.authToken
  sendPackage data, client

W3CWebSocket.prototype.slowMode = (time) ->
  return slowMode time, this

slowMode = (time, client) ->
  unless typeof usr == "number"
    throw new TypeError("Wrong type of user. Expected: Number")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "slowMode"
    params:
      channel:client.channel
      time: time
  sendPackage data, client

W3CWebSocket.prototype.subMode = (bool) ->
  return subMode boole, this

subMode = (bool, client) ->
  unless typeof usr == "boolean"
    throw new TypeError("Wrong type of user. Expected: Boolean")
  unless client instanceof W3CWebSocket
    throw new TypeError("Wrong type of client. Expected: W3CWebSocket")
  data =
    method: "slowMode"
    params:
      channel:client.channel
      subscriber:bool
      rate:"0"
  sendPackage data, client

class triggerController

  constructor: () ->
    this.list = {}

  register: (name, trigger, pluginName, func) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of name. Expected: String")
    unless typeof trigger == "string"
      throw new TypeError("Wrong type of trigger. Expected: String")
    unless typeof pluginName is "string"
      throw new TypeError("Wrong type of pluginName. Expected: String")
    unless typeof func is "function"
      throw new TypeError("Wrong type of function. Expected: function")
    unless typeof this.list[name] is "undefined"
      throw "nameUsed"
    this.list[name] =
      plugin: pluginName
      trigger: new RegExp(trigger)
      func: func
    return

  unRegister: (name) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of name. Expected: String")
    if typeof this.list[name] == "undefined"
      throw "triggerDoesntExist"
    delete this.list[name]
    return

  exec: (str, data) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of string. Expected: String")
    for key, value of this.list
      if this.list[key].trigger.test str
        this.list[key].func data
    return

class commandController

  constructor: (prefix = "!") ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of prefix. Expected: String")
    this.prefix = prefix
    this.list = {}

  register: (name, command, pluginName, func) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of name. Expected: String")
    unless typeof command == "string"
      throw new TypeError("Wrong type of command. Expected: String")
    unless typeof pluginName is "string"
      throw new TypeError("Wrong type of pluginName. Expected: String")
    unless typeof func is "function"
      throw new TypeError("Wrong type of function. Expected: function")
    unless typeof this.list[name] is "undefined"
      throw "nameUsed"
    this.list[name] =
      plugin: pluginName
      command: command
      func: func
    return

  unRegister: (name) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of name. Expected: String")
    if typeof this.list[name] == "undefined"
      throw "triggerDoesntExist"
    delete this.list[name]
    return

  exec: (str, data) ->
    unless typeof name == "string"
      throw new TypeError("Wrong type of string. Expected: String")
    for key, value of this.list
      if str is this.prefix+this.list[key].command
        this.list[key].func data
    return

console.log("Engine Initialized")
