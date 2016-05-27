async = require 'async'
websocketclient = require('websocket').client
getToken = (username, password) =>
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
    return [request.status,request.statusText]
getWSServers = (callback) =>
  request = new XMLHttpRequest()
  request.open "GET", "https://api.hitbox.tv/chat/servers", false
  request.send null
  if request.status is 200
    serverslist = null;
    servers = JSON.parse request.responseText
    servers = async.map(servers, (i, cb) =>
      $.get new String().concat("http://",i.server_ip,"/socket.io/1/"), (data, status) =>
        if status is "success"
          txt = data.split(":")[0]
          add = new String().concat("ws://",i.server_ip,txt)
          console.log add
          cb null, add
    ,(err, results) =>
      callback null, results
      return
    )
    return null
  else
    return error

console.log("Engine Initialized")
