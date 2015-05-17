(function() {
  var Application, BrowserWindow, Menu, Monitor, Rsync, app, crashReporter, watch;

  app = require('app');

  crashReporter = require('crash-reporter').start();

  watch = require('watch');

  Rsync = require('rsync');

  BrowserWindow = require('browser-window');

  Menu = require('menu');

  Monitor = (function() {
    Monitor.prototype.iTunesDirectories = {
      local: '/Users/randall/Music/Local',
      network: '/Users/randall/Music/iTunes'
    };

    Monitor.prototype.synced = true;

    Monitor.prototype.window = null;

    function Monitor(options) {
      this.configureLibraries();
    }

    Monitor.prototype.configureLibraries = function() {
      this.window = new BrowserWindow({
        width: 800,
        height: 600,
        resizable: true
      });
      this.window.loadUrl("file://" + __dirname + "/../templates/index.html");
      this.window.focus();
      return this.window.toggleDevTools();
    };

    Monitor.prototype.monitorLibrary = function() {
      var rsync;
      rsync = new Rsync().source(this.iTunesDirectories.local + "/iTunes\\ Library.itl").destination("/Users/randall/Downloads");
      return watch.createMonitor("" + this.iTunesDirectories.local, function(monitor) {
        monitor.files['iTunes Library.itl'];
        return monitor.on('changed', function(f, curr, prev) {
          this.synced = false;
          return rsync.execute(function(error, code, cmd) {
            return this.synced = true;
          });
        });
      });
    };

    return Monitor;

  })();

  module.exports = Application = (function() {
    function Application(options) {
      new Monitor();
    }

    return Application;

  })();

}).call(this);
