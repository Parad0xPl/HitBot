client = null;
fs = require 'fs'
ipc = require('electron').ipcRenderer
path = require 'path'
appDir = ipc.sendSync 'get-app-path'
pluginsDir = null
$.ready(
  pluginsDir = path.resolve './plugins'
  fs.readDir pluginsDir, (err, files) ->
    async.each files, (file, callback) ->
      mod = require file
  triggers = new triggerController
  commands = new commandController "!"
  directCommand = new commandController "/"
  userToken = getToken "KsawK", ""
  getConnection "KsawK","ksawk", userToken, (cli) =>
    client = cli
    client.onmessage = (e) =>
      if typeof e.data is "string"
        data = e.data
        if data is "2::"
          client.send "2::"
        else if data is "1::"
          console.log data
        else if data.slice(0,4) is "5:::"
          data = JSON.parse(JSON.parse(data.slice(4)).args[0])
          if data.method is "chatMsg"
            console.log "#{data.params.name}: #{data.params.text}"
            unless data.params.name is client.nick
              triggers.exec(data.params.text, data)
              commands.exec(data.params.text, data)
          else if data.method is "infoMsg"
            console.log "SYSTEM: #{data.params.text}"
          else if data.method is "directMsg"
            console.log "#{data.params.from} to #{client.nick}: #{data.params.text}"
            directCommand.exec(data.params.text, data)
          else if data.method is "loginMsg"
            console.log "Logged to #{data.params.channel} as #{data.params.name} with role #{data.params.role}"
          else
            console.log data
        else
          console.log data
)
tempint = setInterval(() ->
  unless client? and triggers?
    return null
  else
    clearInterval tempint
    joinPackage =
      method: "joinChannel"
      params:
        channel:client.channel.toLowerCase()
        name:"KsawK"
        token: userToken
        isAdmin:false
    client.sendPackage joinPackage
, 1000)
