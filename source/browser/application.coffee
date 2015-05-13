app = require "app"
BrowserWindow = require "browser-window"
crashReporter = require("crash-reporter").start()

Monitor = require "./monitor"

module.exports = class Application
  constructor: (options) ->
    new Monitor()
