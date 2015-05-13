(function() {
  var Application, BrowserWindow, Monitor, app, crashReporter;

  app = require("app");

  BrowserWindow = require("browser-window");

  crashReporter = require("crash-reporter").start();

  Monitor = require("./monitor");

  module.exports = Application = (function() {
    function Application(options) {
      new Monitor();
    }

    return Application;

  })();

}).call(this);
