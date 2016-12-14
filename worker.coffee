express = require 'express'
app = express()
coffeeMiddleware = require 'coffee-middleware'
engines = require 'consolidate'
bodyParser = require 'body-parser'
stylish = require 'stylish'
autoprefixer = require 'autoprefixer-stylus'

app.use express.static 'views'

morgan = require 'morgan'
healthChecker = require('sc-framework-health-check')
assets = require './assets'

module.exports = (worker)->
  console.log '   >> Worker PID:', process.pid
  environment = worker.options.environment
  httpServer = worker.httpServer
  scServer = worker.scServer
  app.use morgan 'dev' if environment is 'dev'
  app.engine 'jade', engines.jade

  # sets up coffee-script support
  app.use coffeeMiddleware
    bare: true
    src: "public"
  require('coffee-script/register')
  
  app.use '/', assets
  
  # bodyParser
  app.use bodyParser.urlencoded
    extended: false
  app.use bodyParser.json()
  app.use bodyParser.text()

  healthChecker.attach worker, app
  httpServer.on 'request', app

  ### route ###
  app.get '/', (request, response) ->
    response.render 'index.jade'

  ### main ###
  users = {}
  scServer.on 'connection', (socket) ->
    users[socket.id] = status: true
    socket.on 'message.send', (data) ->
      scServer.exchange.publish 'message.publish',
        Object.assign from: socket.id, data