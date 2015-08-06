app = require 'app'
BrowserWindow = require 'browser-window'
CoffeeScript = require 'coffee-script'

class Notifications
  fakeWindow: null

  constructor: ->
    app.on 'ready', =>
      @fakeWindow = new BrowserWindow
        width: 0
        height: 0
      @fakeWindow.loadUrl('file://')

  notify: (message) =>
    title = message.title.replace("'", '&quote;')
    body = message.body.replace("'", '&quote;')

    template = "new Notification(
      '#{title}'.replace('&quote;', \"'\"),
      {body: '#{body}'.replace('&quote;', \"'\")}
    )"
    @fakeWindow.webContents.executeJavaScript template

module.exports = new Notifications
