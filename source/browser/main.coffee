app = require 'app'
Application = require './application'

global.shellStartTime = Date.now()

start = ->
  app.on 'ready', ->
    require './application'
    global.application = new Application()
    console.log("App load time: #{Date.now() - global.shellStartTime}ms")

start()
