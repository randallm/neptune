app = require 'app'
crashReporter = require('crash-reporter').start()
watch = require 'watch'
BrowserWindow = require 'browser-window'
Tray = require 'tray'
Menu = require 'menu'
ipc = require 'ipc'
LocalStorage = require('node-localstorage').LocalStorage
path = require 'path'
Q = require 'q'
fs = require 'fs'
require 'shelljs/global' # TODO: use namespaced version of shelljs

global.shellStartTime = Date.now()

class App
  window: null
  tray: null
  localStorage: null

  constructor: ->
    Q.all [@killItunes(), @createBaseLibrary()]
      .then @launchItunes

    app.on 'window-all-closed', (e) =>
      @window = null
      app.dock.hide()
      e.preventDefault()

    app.on 'ready', =>
      app.dock.hide()

      @setupLocalStorage()

      @initializeWindow()
      unless @fetchLibraryIds()
        @showPreferences()

      @tray = new Tray "#{__dirname}/trayTemplate@2x.png"

      @populateTray()

    ipc.on 'syncLocalStorage', (e, data) =>
      @syncLocalStorage(e, data)
      @populateTray()

  initializeWindow: ->
    @window or= new BrowserWindow
      width: 600
      height: 600
      resizable: false
      title: ''
      show: false

  setupLocalStorage: =>
    localStorageDir = "#{app.getPath('appData')}/neptune/browser/LocalStorage"

    unless test('-e', localStorageDir)
      mkdir '-p', localStorageDir

      # for testing purposes: if browser side localstorage is destroyed, clear
      # the renderer side localstorage too
      options =
        origin: "file://",
        storages: ['localstorage'],
        quotas: ['persistent'],
      @window.webContents.session.clearStorageData options, ->

    @localStorage = new LocalStorage localStorageDir

  showPreferences: =>
    @initializeWindow()
    app.dock.show()

    @window.webContents.loadUrl("file://#{__dirname}/../renderer/app.html")

    @window.webContents.on 'did-finish-load', =>
      @window.show()

  exit: =>
    app.quit()

  syncLocalStorage: (e, data) =>
    @localStorage.clear()
    store = JSON.parse data

    for key, val of store
      if key is 'libraries'
        val = JSON.stringify(val.split(','))

      @localStorage.setItem key, val

  fetchLibraryIds: =>
    ids = JSON.parse @localStorage.getItem('libraries')

    if ids?.length is 1 and ids?[0] is ''
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
          checked: library.id is @localStorage.getItem('libraries-active-library')
          accelerator: "Cmd+#{template.length + 1}"
          click: @activateLibrary
          library: library

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

  activateLibrary: (menuItem) =>
    itunesKilled = @killItunes()

    library = menuItem.library

    symlinkDest = path.join(process.env.HOME, '/Music/iTunes')
    symlinkSource = path.join(library.path, '..')
    rm symlinkDest
    ln '-s', symlinkSource, symlinkDest

    @localStorage.setItem('libraries-active-library', library.id)
    Q.all [itunesKilled, @populateTray()]
      .then @launchItunes

  killItunes: ->
    deferred = Q.defer()

    command = 'ps aux | grep "/Applications/iTunes.app/Contents/MacOS/iTunes$"'
    exec command, (code, output) ->
      if code is 0
        regex = /\d+/
        pid = output.match(regex)

        exec "kill -15 #{pid}", ->
          deferred.resolve()
      else
        deferred.resolve()

    deferred.promise

  launchItunes: ->
    exec 'open /Applications/iTunes.app', ->

  createBaseLibrary: ->
    deferred = Q.defer()
    baseLibrary = path.join(process.env.HOME, 'Music', 'iTunes')
    mainLibrary = path.join(process.env.HOME, 'Music', 'Main Library')

    unless test('-L', baseLibrary)
      mv baseLibrary, mainLibrary
      ln '-s', mainLibrary, baseLibrary

    script = "defaults delete com.apple.iTunes 'alis:1:iTunes Library Location'"
    exec script, (code, output) ->
      deferred.resolve()

    deferred.promise

start = ->
  global.app = new App()
  console.log("App load time: #{Date.now() - global.shellStartTime}ms")
start()
