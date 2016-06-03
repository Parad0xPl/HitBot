BrowserWindow = (require 'electron').BrowserWindow
mainWindow = null
electron = require "electron"
ipc = electron.ipcMain
debug = true

createWindow = =>
  opt =
    width: 1024
    height: 768
  mainWindow = new BrowserWindow opt
  mainWindow.loadURL "file://#{__dirname}/index.html"
  mainWindow.webContents.openDevTools() if debug
  mainWindow.on 'closed', ->
    mainWindow = null
    return
ipc.on 'get-app-path', (event) =>
  event.returnValue = app.getAppPath()

app = electron.app
app.on "ready", createWindow
app.on "window-all-closed", ->
  unless process.platform is 'darwin'
    app.quit()
    return

app.on "activate", ->
  if mainWindow is null
    createWindow()
    return
