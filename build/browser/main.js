(function() {
  var Application, app, start;

  app = require('app');

  Application = require('./application');

  global.shellStartTime = Date.now();

  start = function() {
    return app.on('ready', function() {
      require('./application');
      global.application = new Application();
      return console.log("App load time: " + (Date.now() - global.shellStartTime) + "ms");
    });
  };

  start();

}).call(this);
