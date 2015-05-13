(function() {
  var Monitor, Rsync, watch;

  watch = require("watch");

  Rsync = require("rsync");

  module.exports = Monitor = (function() {
    Monitor.prototype.iTunesDirectories = {
      local: "/Users/randall/Music/Local",
      network: "/Users/randall/Music/iTunes"
    };

    Monitor.prototype.synced = true;

    function Monitor(options) {
      var rsync;
      rsync = new Rsync().source(this.iTunesDirectories.local + "/iTunes\\ Library.itl").destination("/Users/randall/Downloads");
      watch.createMonitor("" + this.iTunesDirectories.local, function(monitor) {
        monitor.files["iTunes Library.itl"];
        return monitor.on("changed", function(f, curr, prev) {
          this.synced = false;
          return rsync.execute(function(error, code, cmd) {
            return this.synced = true;
          });
        });
      });
    }

    return Monitor;

  })();

}).call(this);
