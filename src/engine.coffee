async = require 'async'
W3CWebSocket = require('websocket').w3cwebsocket

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
          server_ip = new String().concat i.server_ip, "/socket.io/1/websocket/"
          add = new String().concat("ws://",server_ip,txt)
          console.log add
          cb null, add
    ,(err, results) =>
      callback null, results
      return
    )
    return null
  else
    return error

getConnection = (cb) =>
  client = null
  getWSServers((err, list) =>
    test = false
    n = -1;
    async.until(()=>
      n++
      return test || n>=list.length
    ,(callback)=>
      client = new W3CWebSocket list[n]
      client.onerror = () =>
        console.log "Connection Error"
        callback null
      client.onopen = () =>
        console.log('WebSocket Client Connected');
        test = true
        callback null, 2
      client.onclose = () =>
        console.log("Connection Closed")
        callback null
      client.onmessage = (e) =>
        if typeof e.data is "string"
          if e.data is "2::"
            client.send "2::"
      return
    ,(err, n)=>
      if n is 2
        cb client
      return
    ))

console.log("Engine Initialized")
