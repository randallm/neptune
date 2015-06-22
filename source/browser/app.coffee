app = require 'app'
crashReporter = require('crash-reporter').start()
watch = require 'watch'
Rsync = require 'rsync'
BrowserWindow = require 'browser-window'
Menu = require 'menu'

global.shellStartTime = Date.now()

class Monitor
  iTunesDirectories:
    local: '/Users/randall/Music/Local'
    network: '/Users/randall/Music/iTunes'
  synced: true
  window: null

  constructor: (options) ->
    app.on 'ready', ->
      @window = new BrowserWindow
        width: 800
        height: 600
        resizable: true
      @window.loadUrl("file://#{__dirname}/../templates/app.html")
      @window.focus()
      @window.toggleDevTools()

  monitorLibrary: ->
    rsync = new Rsync()
      .source("#{@iTunesDirectories.local}/iTunes\\ Library.itl")
      .destination("/Users/randall/Downloads")

    watch.createMonitor "#{@iTunesDirectories.local}", (monitor) ->
      monitor.files['iTunes Library.itl']
      monitor.on 'changed', (f, curr, prev) ->
        @synced = false
        rsync.execute (error, code, cmd) ->
          @synced = true

start = ->
  global.monitor = new Monitor()
  console.log("App load time: #{Date.now() - global.shellStartTime}ms")
start()
