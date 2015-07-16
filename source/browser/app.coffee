app = require 'app'
crashReporter = require('crash-reporter').start()
watch = require 'watch'
BrowserWindow = require 'browser-window'
Tray = require 'tray'
Menu = require 'menu'
ipc = require 'ipc'
LocalStorage = require('node-localstorage').LocalStorage
path = require('path')
Q = require('q')
require 'shelljs/global'

global.shellStartTime = Date.now()

class App
  window: null
  tray: null
  localStorage: null

  constructor: ->
    @localStorage = new LocalStorage './LocalStorage'

    app.on 'ready', =>
      @window = new BrowserWindow
        width: 800
        height: 600
        resizable: true
      @window.loadUrl("file://#{__dirname}/../renderer/app.html")
      @window.focus()

      @tray = new Tray "#{__dirname}/tray.png"
      @tray.setPressedImage "#{__dirname}/tray_inverse.png"

    ipc.on 'syncLocalStorage', (e, data) =>
      @syncLocalStorage(e, data)
      @populateTray()

    ipc.on 'activateLibrary', (e, data) =>
      @activateLibrary(e, data)

  syncLocalStorage: (e, data) =>
    store = JSON.parse data

    for key, val of store
      if key is 'libraries'
        val = JSON.stringify(val.split(','))

      @localStorage.setItem key, val

  fetchLibraryIds: =>
    JSON.parse @localStorage.getItem('libraries')

  fetchLibrary: (id) =>
    JSON.parse @localStorage.getItem("libraries-#{id}")

  populateTray: =>
    template = []

    for libraryId in @fetchLibraryIds()
      library = @fetchLibrary libraryId

      menuItem =
        label: library.name
        type: 'radio'
        checked: library.active # TODO: check if string or bool

      template.push menuItem

    template = template.concat [
      { type: 'separator' }
      { label: 'Preferences...', type: 'normal' }
    ]

    @tray.setContextMenu Menu.buildFromTemplate(template)

  activateLibrary: (e, data) =>
    itunesDir = path.join(process.env.HOME, "/Music/iTunes")
    libraryDir = @fetchLibrary(data).path

    try
      stats = fs.lstatSync itunesDir
    catch error  # Library doesn't exist yet
      # TODO: display error message
      return process.exit 1

    if stats.isSymbolicLink()
      @resetLibrary()
      ln '-s', libraryDir, itunesDir
    else
      @migrateMainLibrary()

    # TODO: call back to renderer using ipc
    # TODO: set checked in tray icon

  killItunes: ->
    script = 'ps aux | grep "/Applications/iTunes.app/Contents/MacOS/iTunes$"'
    exec script, (code, output) =>
      if code is 0
        regex = /\d+/
        pid = output.match(regex)

        exec "kill -15 #{pid}", ->

  launchItunes: ->
    exec 'open /Applications/iTunes.app', ->

  resetLibrary: ->
    deferred = Q.defer()

    script = "defaults delete com.apple.iTunes 'alis:1:iTunes Library Location'"
    itunesDir = path.join(process.env.HOME, "/Music/iTunes")

    exec script, (code, output) ->
      deferred.resolve()

    rm '-r', itunesDir

    deferred.promise

  migrateMainLibrary: =>
    itunesDir = path.join(process.env.HOME, "/Music/iTunes")
    mainDir = path.join(process.env.HOME, "Music/Main")
    mv itunesDir, mainDir

start = ->
  global.app = new App()
  console.log("App load time: #{Date.now() - global.shellStartTime}ms")
start()
