app = require("app")
BrowserWindow = require("browser-window")

require("crash-reporter").start()

mainWindow = null

app.on "window-all-closed", ->
  app.quit() if process.platform != "darwin"

app.on "ready", ->
  mainWindow = new BrowserWindow({width: 400, height: 400})
  mainWindow.loadUrl("file://" + __dirname + "/index.html")
  mainWindow.on "closed", ->
    mainWindow = null
