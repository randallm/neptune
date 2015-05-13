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
          src: ["*", "!*/*.coffee", ]
          dest: "build"
        ]

  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-clean"

  grunt.registerTask "default", ["clean", "coffee", "copy"]
