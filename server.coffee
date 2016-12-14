fs = require('fs')
argv = require('minimist')(process.argv.slice(2))
SocketCluster = require('socketcluster').SocketCluster
scHotReboot = require('sc-hot-reboot')
workerControllerPath = argv.wc or process.env.SOCKETCLUSTER_WORKER_CONTROLLER
brokerControllerPath = argv.bc or process.env.SOCKETCLUSTER_BROKER_CONTROLLER
initControllerPath = argv.ic or process.env.SOCKETCLUSTER_INIT_CONTROLLER
environment = process.env.ENV or 'dev'
options = 
  workers: Number(argv.w) or Number(process.env.SOCKETCLUSTER_WORKERS) or 1
  brokers: Number(argv.b) or Number(process.env.SOCKETCLUSTER_BROKERS) or 1
  port: Number(argv.p) or Number(process.env.SOCKETCLUSTER_PORT) or 8000
  wsEngine: process.env.SOCKETCLUSTER_WS_ENGINE or 'uws'
  appName: argv.n or process.env.SOCKETCLUSTER_APP_NAME or null
  workerController: workerControllerPath or __dirname + '/worker.js'
  brokerController: brokerControllerPath or __dirname + '/broker.js'
  initController: initControllerPath or null
  socketChannelLimit: Number(process.env.SOCKETCLUSTER_SOCKET_CHANNEL_LIMIT) or 1000
  clusterStateServerHost: argv.cssh or process.env.SCC_STATE_SERVER_HOST or null
  clusterStateServerPort: process.env.SCC_STATE_SERVER_PORT or null
  clusterAuthKey: process.env.SCC_AUTH_KEY or null
  clusterStateServerConnectTimeout: Number(process.env.SCC_STATE_SERVER_CONNECT_TIMEOUT) or null
  clusterStateServerAckTimeout: Number(process.env.SCC_STATE_SERVER_ACK_TIMEOUT) or null
  clusterStateServerReconnectRandomness: Number(process.env.SCC_STATE_SERVER_RECONNECT_RANDOMNESS) or null
  crashWorkerOnError: argv['auto-reboot'] != false
  killMasterOnSignal: false
  environment: environment
SOCKETCLUSTER_OPTIONS = undefined
if process.env.SOCKETCLUSTER_OPTIONS
  SOCKETCLUSTER_OPTIONS = JSON.parse(process.env.SOCKETCLUSTER_OPTIONS)
for i of SOCKETCLUSTER_OPTIONS
  if SOCKETCLUSTER_OPTIONS.hasOwnProperty(i)
    options[i] = SOCKETCLUSTER_OPTIONS[i]
masterControllerPath = argv.mc or process.env.SOCKETCLUSTER_MASTER_CONTROLLER

start = ->
  socketCluster = new SocketCluster(options)
  if masterControllerPath
    masterController = require(masterControllerPath)
    masterController.run socketCluster
  if environment == 'dev'
    # This will cause SC workers to reboot when code changes anywhere in the app directory.
    # The second options argument here is passed directly to chokidar.
    # See https://github.com/paulmillr/chokidar#api for details.
    console.log "   !! The sc-hot-reboot plugin is watching for code changes in the #{__dirname} directory"
    scHotReboot.attach socketCluster,
      cwd: __dirname
      ignored: [
        'views'
        'node_modules'
        'README.md'
        'Dockerfile'
        'server.js'
        'broker.js'
        /[\/\\]\./
      ]

bootCheckInterval = Number(process.env.SOCKETCLUSTER_BOOT_CHECK_INTERVAL) or 200
if workerControllerPath
  # Detect when Docker volumes are ready.

  startWhenFileIsReady = (filePath) ->
    new Promise (resolve) ->
      if !filePath
        resolve()
        return
      checkIsReady = ->
        fs.exists filePath, (exists) ->
          if exists
            resolve()
          else
            setTimeout checkIsReady, bootCheckInterval
      checkIsReady()

  filesReadyPromises = [
    startWhenFileIsReady(masterControllerPath)
    startWhenFileIsReady(workerControllerPath)
    startWhenFileIsReady(brokerControllerPath)
    startWhenFileIsReady(initControllerPath)
  ]
  Promise.all(filesReadyPromises).then start
else
  start()
