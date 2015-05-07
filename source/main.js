(function() {
  var BrowserWindow, app, mainWindow;

  app = require("app");

  BrowserWindow = require("browser-window");

  require("crash-reporter").start();

  mainWindow = null;

  app.on("window-all-closed", function() {
    if (process.platform !== "darwin") {
      return app.quit();
    }
  });

  app.on("ready", function() {
    mainWindow = new BrowserWindow({
      width: 400,
      height: 400
    });
    mainWindow.loadUrl("file://" + __dirname + "/index.html");
    return mainWindow.on("closed", function() {
      return mainWindow = null;
    });
  });

}).call(this);
