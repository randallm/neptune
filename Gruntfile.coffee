module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    clean: ["build/**"]
    coffee:
      compile:
        files: [
          expand: true
          cwd: "source"
          src: ["**/*.coffee"]
          dest: "build"
          ext: ".js"
        ]
    copy:
      main:
        files: [
          expand: true
          cwd: "source"
          src: ["**", "!*/*.coffee"]
          dest: "build"
        ]
    jst:
      compile:
        options:
          templateSettings:
            interpolate: /\{\{(.+?)\}\}/g
        files:
          "build/renderer/templates.js": ["source/renderer/views/templates/*.html"]
    exec:
      launch: "./node_modules/.bin/electron build/browser/app.js --debug-brk=5858"
    electron:
      osxBuild:
        options:
          name: "Neptune"
          dir: "./"
          out: "dist"
          icon: "icon.icns"
          version: "0.30.0"
          platform: "darwin"
          arch: "x64"
          ignore: "node_modules/electron-*|node_modules/grunt-*|node_modules/node-inspector|source"
          overwrite: true

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-jst"
  grunt.loadNpmTasks "grunt-exec"
  grunt.loadNpmTasks "grunt-electron"

  grunt.registerTask "build", ["clean", "coffee", "copy", "jst"]
  grunt.registerTask "default", ["build", "exec"]
  grunt.registerTask "package", ["build", "electron"]
