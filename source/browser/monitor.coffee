watch = require "watch"
Rsync = require "rsync"

module.exports = class Monitor
  iTunesDirectories:
    local: "/Users/randall/Music/Local"
    network: "/Users/randall/Music/iTunes"
  synced: true

  constructor: (options) ->
    rsync = new Rsync()
      .source("#{@iTunesDirectories.local}/iTunes\\ Library.itl")
      .destination("/Users/randall/Downloads")

    watch.createMonitor "#{@iTunesDirectories.local}", (monitor) ->
      monitor.files["iTunes Library.itl"]
      monitor.on "changed", (f, curr, prev) ->
        @synced = false
        rsync.execute (error, code, cmd) ->
          @synced = true
