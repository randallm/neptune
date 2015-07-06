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
          "build/renderer/templates.js": [
            "source/renderer/views/templates/*.html",
            "!source/renderer/views/templates/index.html"
          ]
    exec:
      launch: "./node_modules/.bin/electron build/browser/app.js --debug"

  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-jst"
  grunt.loadNpmTasks "grunt-exec"

  grunt.registerTask "default", ["clean", "coffee", "copy", "jst", "exec"]
