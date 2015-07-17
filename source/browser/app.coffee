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

    app.on 'window-all-closed', (e) ->
      app.dock.hide()
      e.preventDefault()

    app.on 'ready', =>
      app.dock.hide()

      unless @fetchLibraryIds()?
        @showPreferences()

      @tray = new Tray "#{__dirname}/tray.png"
      @tray.setPressedImage "#{__dirname}/tray_inverse.png"

      @populateTray()

    ipc.on 'syncLocalStorage', (e, data) =>
      @syncLocalStorage(e, data)
      @populateTray()

    ipc.on 'activateLibrary', (e, data) =>
      @activateLibrary(e, data)

  showPreferences: =>
    app.dock.show()

    @window = new BrowserWindow
      width: 800
      height: 600
      resizable: false

    @window.webContents.loadUrl("file://#{__dirname}/../renderer/app.html")
    @window.hide()

    @window.webContents.on 'did-finish-load', =>
      @window.show()

    @window.on 'closed', ->
      @window = null

  hidePreferences: =>
    @window?.hide()

  exit: =>
    app.quit()

  syncLocalStorage: (e, data) =>
    store = JSON.parse data

    for key, val of store
      if key is 'libraries'
        val = JSON.stringify(val.split(','))

      @localStorage.setItem key, val

  fetchLibraryIds: =>
    ids = JSON.parse @localStorage.getItem('libraries')

    if ids.length is 1 and ids[0] is ''
      ids = null

    ids

  fetchLibrary: (id) =>
    JSON.parse @localStorage.getItem("libraries-#{id}")

  populateTray: =>
    template = []
    libraryIds = @fetchLibraryIds()

    if libraryIds
      for libraryId in libraryIds
        library = @fetchLibrary libraryId

        menuItem =
          label: library.name
          type: 'radio'
          checked: library.active
          accelerator: "Cmd+#{template.length + 1}"

        template.push menuItem
    else
      template.push
        label: 'No libraries setup'
        enabled: false
        type: 'normal'

    template = template.concat [
      { type: 'separator' }
      { label: 'Preferences...', type: 'normal', accelerator: 'Cmd+,', click: @showPreferences }
      { label: 'Quit', type: 'normal', click: @exit }
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
