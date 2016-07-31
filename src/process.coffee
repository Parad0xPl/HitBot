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
user = null
pass = null
lastUser = null
listInterval = null

plugins = {}
pluginsDir = path.resolve './plugins'
pluginInit pluginsDir, plugins
triggers = new triggerController
commands = new commandController "!"
directCommands = new commandController "/"

addMessage = null

$html = {}

drawSettings = (sett, configName) =>
  console.log sett
  $html.pluginSetting.empty();
  $html.pluginSetting.attr "configName", configName
  for x in sett.hierarchy
    if x.type is "label"
      node = $("""
      <label id="#{x.id}" for="basic-url">#{x.name}</label>
      """)
    else if x.type is "text"
      node = $("""
        <div class="input-group">
          <span class="input-group-addon" id="basic-addon1">#{x.name}</span>
          <input id="#{x.id}" type="text" class="form-control" value="#{x.defaultValue}">
        </div>
      """)
    else if x.type is "password"
      node = $("""
        <div class="input-group">
          <span class="input-group-addon" id="basic-addon1">#{x.name}</span>
          <input id="#{x.id}" type="password" class="form-control" value="#{x.defaultValue}">
        </div>
      """)
    else if x.type is "button"
      node = $("""
        <div class="input-group clearfix">
        </div>
      """)
      btn = $("""
        <button id="#{x.id}" type="button" class="btn btn-primary pull-right">#{x.name}</button>
      """)
      if x.func?
        btn.click x.func
      node.append btn
    $html.pluginSetting.append node
    $html.pluginSetting.append $("</br>")
  return

packedDrawSettings = (a, b) ->
  return () ->
    drawSettings(a, b)
    return

onShow = {}
onShow["settings"] = () ->
  $html.pluginsList = $("#settings #pluginsList")
  $html.pluginSetting = $("#settings #pluginSetting")
  if plugins[0] instanceof Array
    $html.pluginsList.empty();
    $html.pluginSetting.empty();
    for x in plugins[0]
      node = $("<span>#{x.name}</span>")
      console.log x
      node.click packedDrawSettings(x.settings, x.confignNme)
      $html.pluginsList.append(node);
      $html.pluginsList.append("</br>");
  return

$(document).ready( () ->
  #part about html
  navButtons = $(".nav a")
  navButtons.click () ->
    id = $(this).attr "id"
    if typeof onShow[id] is "function"
      onShow[id]();
    viewport = $("div#viewport div##{id}")
    viewport.css "display", "block"
    viewport.siblings().css "display", "none"
    return

  #part about process
  $html.channel = $("#main #channelBar")
  $html.status = $("#main #statusBar")
  $html.role = $("#main #roleBar")
  $html.btnConnect = $("#main #btnConnect")
  $html.chat = $("#main #chat")
  $html.list = $("#main #userList")

  $("#settings #btnSave").click () ->
    user = $("#stgLogin").val()
    pass = $("#stgPassword").val()

  $("#chatInput").keypress (e) ->
    unless client? && client.readyState is 1
      return false
    if $("#chatInput").is(':focus') && e.which is 13 && client
      client.sendMessage $("#chatInput").val()
      $("#chatInput").val ""
      return false

  subImg = null
  addToList = (usr, status, sub = 0) ->
    if subImg is null
      request = new XMLHttpRequest()
      request.open "GET", "https://api.hitbox.tv/mediabadges/#{client.channel}", false
      request.send()
      if request.status is 200
        console.debug JSON.parse(request.response)
        subImg = "https://edge.sf.hitbox.tv/"+JSON.parse(request.response).badges[0].badge_image
      else
        console.log request.status, request.statusText
    node = $("<li class=\"list-group-item\"></li>")
    if status is "admin"
      node.append "<span class=\"badge\">Admin</span>"
    else if status is "mod"
      node.append "<span class=\"badge\">Mod</span>"
    else if status is "user"
      null
    if sub
      node.append("<img id=\"badge\" src=\"#{subImg}\" style=\"\"></img>")
    node.append usr
    $html.list.append node

  addToChat = (x) ->
    if Math.abs($html.chat[0].scrollHeight - $html.chat[0].scrollTop - $html.chat[0].clientHeight) < 5
      flag = 1
    else
      flag = 0
    $html.chat.append x
    if flag
      $html.chat.scrollTop($html.chat[0].scrollHeight)
    return

  addNick = (nick, color) ->
    addToChat "<div id=\"nick\" style=\"color:#{color}\">#{nick}</div>"

  addMessage = (message) ->
    addToChat "<div id=\"message\">#{message}</div>"

  setColor = (element, clrClass) ->
    set = ["err", "suc"]
    if element.hasClass clrClass
      return
    for x in set
      if element.hasClass x
        element.removeClass x
        element.addClass clrClass
        return
    element.addClass x
    return

  setAlert = (message, time = 1000) ->
    setColor $html.status, "err"
    $html.status.val message
    setTimeout( () ->
      if $html.status.val() is message
        setColor $html.status, "err"
        $html.status.val "Offline"
    , time)

  $html.btnConnect.click () ->
    channel = $html.channel.val()
    console.log channel
    if channel is ""
      setAlert "Channel is needed"
      return
    if isUser channel.toLowerCase()
      setAlert "Channel does not exit"
      return
    if user is "" or user is null
      setAlert "User is needed"
      return
    if isUser user.toLowerCase()
      setAlert "User does not exit"
      return
    if pass is "" or pass is null
      setAlert "Password is needed"
      return
    userToken = getToken user, pass
    unless typeof userToken is "string"
      setAlert "Authentication fail"
      return
    getConnection "KsawK",channel.toLowerCase(), userToken, (cli) ->
      client = cli
      client.onmessage = (e) ->
        if typeof e.data is "string"
          data = e.data
          if data is "2::"
            client.send "2::"
          else if data is "1::"
          else if data.slice(0,4) is "5:::"
            data = JSON.parse(JSON.parse(data.slice(4)).args[0])
            if data.method is "chatMsg"
              unless lastUser is data.params.name
                addNick data.params.name, "#"+data.params.nameColor
                lastUser = data.params.name
              addMessage data.params.text
              unless data.params.name is client.nick
                triggers.exec(data.params.text, data)
                commands.exec(data.params.text, data)
            else if data.method is "infoMsg"
            else if data.method is "directMsg"
              directCommands.exec(data.params.text, data)
            else if data.method is "userList"
              $html.list.children().remove()
              data.params.data.admin.sort()
              data.params.data.user.sort()
              data.params.data.anon.sort()
              for item in data.params.data.admin
                addToList item, "admin", data.params.data.isSubscriber.indexOf(item) != -1
              for item in data.params.data.user
                addToList item, "mod", data.params.data.isSubscriber.indexOf(item) != -1
              for item in data.params.data.anon
                if data.params.data.isSubscriber.indexOf(item) != -1
                  addToList item, "user", 1
              for item in data.params.data.anon
                if data.params.data.isSubscriber.indexOf(item) == -1
                  addToList item, "user", 0
            else if data.method is "banList"
              null
            else if data.method is "loginMsg"
              $html.status.val "Online"
              setColor $html.status, "suc"
              $html.role.val data.params.role.charAt(0).toUpperCase()+data.params.role.slice(1)
              listInterval = setInterval(() ->
                data =
                  method: "getChannelUserList"
                  params:
                    channel:client.channel
                client.sendPackage data
              , 5000)
              data =
                method: "getChannelUserList"
                params:
                  channel:client.channel
              client.sendPackage data
            else
              console.log data
          else
            console.log data
  return
)
tempint = setInterval(() ->
  unless client? and triggers? and plugins[0]?
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
