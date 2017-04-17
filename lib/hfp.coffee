DBus = require 'dbus'
name = require('../package.json').name
debug = require('debug')("#{name}:core")
mpDebug = require('debug')("#{name}:mediaPlayer")
Promise = require 'promise'
util = require 'util'
{EventEmitter} = require 'events'

# Bluetooth AVRCP controller that extends the {EventEmitter} prototype.
#
# @example How to use
#   avrcp = new AVRCP()
#     avrcp.on('ready', ->
#     avrcp.setPairable(true)
#     avrcp.setDiscoverable(true).then(() ->
#       avrcp.discovery(true)
#       setTimeout(->
#         avrcp.discovery(false)
#       , 50000)
#     )
#   )
#
#   avrcp.on('propertiesChanged', (a) ->
#     console.log a.args[0]
#   )
#
#   avrcp.on('deviceFound', (a) ->
#     avrcp.selectDevice(a).then( ->
#       avrcp.discovery(false)
#       avrcp.getMediaPlayer().then((mp) ->
#         mp.play()
#         mp.getTrack().then((track) ->
#           console.log track
#         )
#       )
#     )
#   )
class HFP extends EventEmitter

  # Default service UUID
  @SERVICE_UUID: utils.SERVICE_UUIDS.Handsfree
  # Default dbus service
  @BUS_SERVICE: 'org.ofono'


  # System bus
  bus: DBus.getBus 'system'

  # Manager interface
  manager: null

  # Device to control
  hfp: null

  # Binding the signal listener of the system dbus
  # and parsers the incoming signal
  # @method
  # @return {undefined}
  _bindListeners = (self) ->
    self.bus.on('signal', (bus, sender, path, iface, signal, args) ->
      utils.parseSignal(self, path, iface, signal, args)
    )
    return

  # Register signal handerls for the system dbus
  # @private
  # @return {undefined}
  _registerHandlers = (self) ->
    utils.registerHandlers(self)

  # Sets properties on interface
  # @private
  # @return {boolean} Promise
  _setProperty = (service, prop, state) ->
    debug "Set #{prop} to #{state}..."
    return new Promise((resolve, reject) ->
      service.setProperty(prop, state, (err) ->
        if !err
          debug "#{prop} is now #{state}."
          return resolve(state)
        else
          return reject(err)
      )
    )

  # Start/stops discovery of bluetooth devices
  # @private
  # @return {boolean} Promise
  _setDiscovery = (self, state) ->
    return new Promise((resolve, reject) ->
      if state isnt false
        debug "Started discovering..."
        self.adapter.startDiscovery(next)
      else
        debug "Stopped discovering."
        self.adapter.stopDiscovery(next)

    next = (err) ->
      if !err
        return resolve(state)
      else
        return reject(err)
    )

  # Register new handler for signals of given interface
  #
  # @param {string} path - object path to listen on
  # @param {string} iface - interace of the given path
  # @param {Interface} signalInterface - interface to use
  #
  # @return {boolean} Promise
  registerHandler: (path, iface, signalInterface) ->
    return utils.registerHandler(@, path, iface, signalInterface)

  # Turn controller on or off
  #
  # @param {boolean} state - true = on / false = off
  #
  # @return {boolean} Promise
  setPower: (state) ->
    return _setProperty(@, 'Powered', state)

  # Allow pairing of this controller
  #
  # @param {boolean} state - true = is pairable / false = is not pairable
  #
  # @return {boolean} Promise
  setPairable: (state) ->
    return _setProperty(@, 'Pairable', state)

  # Make this controler visible for other bluetooth devices
  #
  # @param {boolean} state - true = is discoverable / false = is not discoverable
  #
  # @return {boolean} Promise
  setDiscoverable: (state) ->
    return _setProperty(@, 'Discoverable', state)

  # Start/Stop discovering bluetooth devices
  #
  # @param {boolean} state - true = on / false = off
  #
  # @return {undefined}
  discovery: (state) ->
    return _setDiscovery(@, state)

  # Select a found device and establish a connection
  #
  # @param {object} org.bluez.Device object
  #
  # @return {boolean} Promise
  selectDevice: (device) ->
    debug "Selecting device \"#{device.device.Name}\""
    return new Promise((resolve, reject) =>
      utils.getInterface(@, device.path, device.interface)
      .then( (iface) =>
        @device = iface
        @device.setProperty('Trusted', true)
        #service = utils.findServiceUUID(device.device)

        if device.device.Connected isnt true
          debug "Trying to connect to \"#{device.device.Name}\""
          @device.Connect((err) ->
            if err
              debug "Error while connecting: #{err}"
              return reject(err)
            else
              debug "Connection to \"#{device.device.Name}\" established"
              return resolve(true)
          )
        else
          debug "Already connected with \"#{device.device.Name}\""
          return resolve(true)
        return
      )
    )

  # Get the current media player interface
  #
  # @return {object} Promise
  getMediaPlayer: () ->
    return new Promise((resolve, reject) =>
      @manager.GetManagedObjects((err, objects) =>
        player = utils.checkForPlayer(@, objects)
        utils.getInterface(@, player.path, player.interface)
        .then( (iface) =>
          @media = iface
          debug "Connected to Media Player"
          return resolve(mediaPlayerControls(@media))
        )
        return
      )
      return
    )

  mediaPlayerControls = (player) ->
    return {
      play: () ->
        mpDebug('play')
        player.Play()

      pause: () ->
        mpDebug('pause')
        player.Pause()

      stop: () ->
        mpDebug('stop')
        player.Stop()

      next: () ->
        mpDebug('next track')
        player.Next()

      prev: () ->
        mpDebug('prev track')
        player.Previous()

      shuffle: (type) ->
        mpDebug("shuffle \"#{type}\"")
        if ['off', 'alltracks', 'group'].indexOf(type) isnt -1
          player.Shuffle(type)
        else
          player.Shuffle('off')

      repeat: (type) ->
        mpDebug("shuffle \"#{type}\"")
        if ['off', 'singletrack', 'alltracks', 'group'].indexOf(type) isnt -1
          player.Repeat(type)
        else
          player.Repeat('off')

      getTrack: () ->
        mpDebug('track info')
        return new Promise((resolve, reject) ->
          player.getProperty('Track', (err, track) ->
            if err
              return reject(err)
            else
              return resolve(track)
          )
          return
        )
    }

  getDeviceAlerts: ->
    new Promise((resolve, reject) =>
      utils.getInterface(@, '/org/bluez', 'org.bluez.Alert1')
      .then( (iface) =>
        @alert = iface
        console.log iface
        return resolve()
      )
    )

  # AVRCP Class to controle audio of a bluetooth device.
  #
  # @param  {string} serviceUUID=0000110b - ServiceUUID to connect to.
  #
  # @return {AVRCP} Class Instance
  constructor: (serviceUUID) ->
    @SERVICE_UUID = serviceUUID.toLowerCase() if serviceUUID
    _bindListeners(@)

    utils.getInterface(@, '/', 'org.ofono.Manager')
    .then( (iface) =>
      @manager = iface
      @manager.GetModems((err, modems) =>
        modems.forEach((modem) =>
          path = Object.keys(modem)[0]
          console.log modem, path
          if modem[path].Name.indexOf('Galaxy') isnt -1
            utils.getInterface(@, path, 'org.ofono.Modem').then((iface) =>
              @hfp = iface
              @hfp.GetProperties(console.log)
              @hfp.SetProperty('Powered', true)
              @hfp.SetProperty('Online', true)
              @hfp.SetProperty('Lockdown', true)
              self = @
              setTimeout(->
                self.hfp.GetProperties(console.log)
              , 10000)
            , (err) -> console.log err)
        )
      )
      # _registerHandlers(@).then((res) =>
      #   if res.indexOf(false) is -1
      #     @setPower(true).then( () =>
      #       @.emit('ready')
      #       utils.getInterface(@, '/', 'org.freedesktop.DBus.ObjectManager')
      #       .then( (iface) =>
      #         @manager = iface
      #         @manager.GetManagedObjects((err, objects) =>
      #           utils.checkForDevice(@, objects)
      #           return
      #         )
      #         return
      #       )
      #       return
      #     )
      #   return
      # )
      # return
    )
    return

# @message Put the utils to the end so we can use the class variables
utils = require('./utils')(HFP)

avrcp = new HFP()
# avrcp.on('ready', ->
#   avrcp.setPairable(true)
#   avrcp.setDiscoverable(true).then(() ->
#     avrcp.getDeviceAlerts()
#   )
# )
#
# avrcp.on('propertiesChanged', (a) ->
#   console.log a.args[0]
# )
#
# avrcp.on('deviceFound', (a) ->
#   console.log a
# avrcp.selectDevice(a).then( ->
#     avrcp.getMediaPlayer().then((mp) ->
#       mp.next()
#       mp.getTrack().then((track) ->
#         console.log track
#       )
#     )
# )
#)
