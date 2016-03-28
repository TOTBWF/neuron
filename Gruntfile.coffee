module.exports = (grunt) ->
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json')
    less: {
      development: {
        files: {
          './main.css': './src/main.less'
        }
      }
    }
    coffee: {
      compile: {
        files: {
          './neuron.js': './src/neuron.coffee'
          './spec/nodeSpec.js': './src/spec/nodeSpec.coffee'
          './spec/networkSpec.js': './src/spec/networkSpec.coffee'
        }
      }
    }
    jade: {
      debug: {
        options: {
          data: {
            'pretty': true
            'debug': true
          }
        }
        files: {
          './index.html': './src/index.jade'
        }
      }
      release: {
        options: {
          'debug': false
        }
        files: {
          './index.html': './src/index.jade'
        }
      }
    }
    jasmine: {
      src: "./*.js"
      options: {
        vendor: [
          'node_modules/jquery/dist/jquery.js',
          'node_modules/d3/d3.js',
          'node_modules/jasmine-jquery/lib/jasmine-jquery.js'
        ]
        specs: "./spec/*Spec.js"
      }
    }
    connect: {
      server: {
        options: {
          port: 3000
          debug: true
          keepalive: true
        }
      }
    }
  })


  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-jasmine')
  grunt.loadNpmTasks('grunt-contrib-connect')
  # Set tasks
  grunt.registerTask('build',['less', 'coffee', 'jade'])
  grunt.registerTask('test', ['build', 'jasmine'])
  grunt.registerTask('run', ['build', 'connect'])
