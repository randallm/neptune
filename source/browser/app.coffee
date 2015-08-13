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
Notifications = require './notifications'
require 'shelljs/global' # TODO: use namespaced version of shelljs

global.shellStartTime = Date.now()

class App
  window: null
  tray: null
  localStorage: null

  constructor: ->
    app.on 'ready', =>
      app.dock.hide()

      @setupWindow()
      @setupLocalStorage()
      @setupBaseLibrary()

      unless @fetchLibraryIds()
        @showEditor()

      @tray = new Tray "#{__dirname}/trayTemplate@2x.png"

      @populateTray()

    ipc.on 'syncLocalStorage', (e, data) =>
      @syncLocalStorage(e, data)
      @populateTray()

  setupWindow: ->
    @window = new BrowserWindow
      width: 600
      height: 600
      resizable: false
      title: ''
      show: false

    @window.on 'closed', ->
      app.dock.hide()

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

  showEditor: =>
    @setupWindow()
    app.dock.show()

    @window.webContents.loadUrl("file://#{__dirname}/../renderer/app.html")

    @window.webContents.on 'did-finish-load', =>
      @window.show()

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
      { label: 'Add/Remove Libraries...', type: 'normal', accelerator: 'Cmd+,', click: @showEditor }
      { type: 'checkbox', label: 'Launch Neptune at login', checked: JSON.parse(@localStorage.getItem('app-auto-start')), click: @toggleOpenAtLogin }
      { label: 'Quit', type: 'normal', click: app.quit }
    ]

    @tray.setContextMenu Menu.buildFromTemplate(template)

  activateLibrary: (menuItem) =>
    itunesKilled = @killItunes()

    library = menuItem.library

    symlinkDest = path.join(app.getPath('home'), '/Music/iTunes')
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

  launchItunes: (opts) ->
    if opts.background
      exec 'open -g -a iTunes', ->
    else
      exec 'open -a iTunes', ->

  setupBaseLibrary: ->
    exec 'lsof -c iTunes | grep "iTunes Library.itl" -m 1', (code, output) =>
      if code is 0
        libraryPath = output.slice(output.indexOf('/')).trim()
        activeLibrary = @fetchLibrary @localStorage.getItem('libraries-active-library')

        if libraryPath isnt activeLibrary?.path
          Q.all [@killItunes(), @resetLibrary()]
            .then =>
              baseLibrary = path.join(app.getPath('home'), 'Music', 'iTunes')
              mainLibrary = path.join(app.getPath('home'), 'Music', 'Main Library')

              unless test('-L', baseLibrary)
                mv baseLibrary, mainLibrary
                ln '-s', mainLibrary, baseLibrary

              @launchItunes {background: true}
        else
          @launchItunes {background: true}
      else
        @launchItunes {background: true}

  resetLibrary: ->
    deferred = Q.defer()

    script = "defaults delete com.apple.iTunes 'alis:1:iTunes Library Location'"
    exec script, (code, output) ->
      deferred.resolve()

    deferred.promise

  toggleOpenAtLogin: (menuItem) =>
    if __dirname.startsWith '/Applications/Neptune.app'
      openAtLogin = not JSON.parse(@localStorage.getItem('app-auto-start'))

      @_toggleOpenAtLogin openAtLogin
      @localStorage.setItem 'app-auto-start', JSON.stringify(openAtLogin)
      @populateTray()
    else
      Notifications.notify
        title: '"Launch Neptune at login" Error'
        body: "Neptune isn't in your Applications folder. Please move Neptune and try again."

  _toggleOpenAtLogin: (openAtLogin) ->
    plist = 'com.randallma.Neptune.restart.plist'
    launchAgents = path.join(app.getPath('appData'), '..', 'LaunchAgents')

    rm path.join(launchAgents, plist)
    cp path.join(__dirname, plist), launchAgents

    action = if openAtLogin then 'load' else 'remove'
    exec "launchctl #{action} #{path.join(launchAgents, plist)}", (code, output) ->

start = ->
  global.app = new App()
  console.log("App load time: #{Date.now() - global.shellStartTime}ms")
start()
