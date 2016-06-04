client = null;
fs = require 'fs'
ipc = require('electron').ipcRenderer
path = require 'path'
appDir = ipc.sendSync 'get-app-path'
pluginsDir = null
triggers = null
commands = null
directCommands = null
userToken = null
$(document).ready( () ->
  pluginsDir = path.resolve './plugins'
  triggers = new triggerController
  commands = new commandController "!"
  directCommands = new commandController "/"
  fs.readdir pluginsDir, (err, files) ->
    async.each files, (file, callback) ->
      file = path.resolve "./plugins/#{file}"
      if new RegExp(/.*.js/g).test(file)
        plugin = require file
        console.log plugin
        unless typeof plugin.apiVersion is "string"
          throw new TypeError("ApiVersion is not a String")
          callback "ApiVersion is not a String"
          return
        else
          if plugin.apiVersion is "1.0"
            unless typeof plugin.name is "string"
              throw new TypeError("Name is not a String")
              callback "Name is not a String"
              return
            unless typeof plugin.init is "function"
              throw new TypeError("Init is not a Function")
              callback "Init is not a Function"
              return
            else
              plugin.init()
            unless plugin.triggers instanceof Array
              throw new TypeError("Triggers is not an Array")
              callback "Triggers is not an Array"
              return
            else
              for trg in plugin.triggers
                triggers.register trg.name, trg.trigger, plugin.name, trg.func
            unless plugin.commands instanceof Array
              throw new TypeError("Commands is not an Array")
              callback "Commands is not an Array"
              return
            else
              for cmd in plugin.commands
                commands.register cmd.name, cmd.trigger, plugin.name, cmd.func
            callback()
            return
          else
            callback "Wrong api version"
            return

  userToken = getToken "KsawK", ""
  getConnection "KsawK","ksawk", userToken, (cli) ->
    client = cli
    client.onmessage = (e) ->
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
            directCommands.exec(data.params.text, data)
          else if data.method is "loginMsg"
            console.log "Logged to #{data.params.channel} as #{data.params.name} with role #{data.params.role}"
          else
            console.log data
        else
          console.log data
  return
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
