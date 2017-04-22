DBus = require 'dbus'
name = require('../package.json').name
debug = require('debug')("#{name}:core")
mpDebug = require('debug')("#{name}:mediaPlayer")
Promise = require 'promise'
util = require 'util'
{EventEmitter} = require 'events'
vCard = require 'vcard-json'

# Bluetooth AVRCP/HFP controller that extends the {EventEmitter} prototype.
#
# @example How to use
#   phony = new Phony()
#   phony.on('ready', ->
#   phony.setPairable(true)
#   phony.setDiscoverable(true).then(() ->
#     phony.discovery(true)
#       setTimeout(->
#         phony.discovery(false)
#       , 50000)
#     )
#   )
#
#   phony.on('propertiesChanged', (a) ->
#     console.log a.args[0]
#   )
#
#   phony.on('deviceFound', (a) ->
#     phony.selectDevice(a).then( ->
#       phony.discovery(false)
#       phony.getMediaPlayer().then((mp) ->
#         mp.play()
#         mp.getTrack().then((track) ->
#           console.log track
#         )
#       )
#     )
#   )
class Phony extends EventEmitter

  # Default service UUID
  @SERVICE_UUID: null
  # Default dbus service
  @BUS_SERVICE: 'org.bluez'


  # System bus
  bus: DBus.getBus 'system'

  # Session bus
  sess: DBus.getBus 'session'

  # OBEX Session
  session: {}

  # Adapter interface
  adapter: null

  # Manager interface
  manager: null

  # Session Manager interface
  sessManager: null

  # Device to control
  device: null

  # Player to control
  media: null

  # Device modem
  modem: null

  phonebook: null

  messages: {}

  currentCall: null


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
  _setProperty = (self, prop, state) ->
    debug "Set #{prop} to #{state}..."
    return new Promise((resolve, reject) ->
      self.adapter.setProperty(prop, state, (err) ->
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
    debug "Available Services:" , utils.getServiceNames(device.device.UUIDs)
    return new Promise((resolve, reject) =>
      utils.getInterface(@, device.path, device.interface)
      .then( (iface) =>
        @device = iface
        @device.setProperty('Trusted', true)

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

  connectHandsfree: ->
    new Promise((resolve, reject) =>
      @device.ConnectProfile(utils.SERVICE_UUIDS.Handsfree, (err, profile) =>
        if err
          debug 'Can not connect to Handsfree Service'
          return reject(err)

        @device.ConnectProfile(utils.SERVICE_UUIDS.PhoneBookPBAP, (err, pb) =>
          if err
            debug 'Can not connect to Phonebook PBAP'
            return reject(err)
          # @device.ConnectProfile(utils.SERVICE_UUIDS.MessageAccessServer, (err, sms) =>
          #   if err
          #     debug 'Can not connect to Message Access Server'
          #     return reject(err)
          @device.ConnectProfile(utils.SERVICE_UUIDS.SerialPort, (err, port) =>
            if err
              debug 'Can not connect to SerialPort'
              return reject(err)
            @device.ConnectProfile(utils.SERVICE_UUIDS.AdvancedAudioDistribution, (err, obex) =>
              if err
                debug 'Can not connect to Audio'
                return reject(err)
              @device.ConnectProfile(utils.SERVICE_UUIDS.SIMAccess, (err, sim) ->
                if err
                  debug 'Can not connect to Phonebook PBAP'
                  return reject(err)
                else
                  debug 'Handsfree, Sim Access, SMS and Phonebook Profiles connected'
                  return resolve(true)
              )
            )
          )
          # )
        )
      )
    )

  createOBEXSession: (type) ->
    new Promise((resolve, reject) =>
      utils.getSessInterface(@, '/org/bluez/obex', 'org.bluez.obex.Client1', 'org.bluez.obex').then((iface) =>
        iface.CreateSession('84:2E:27:03:10:5D', {
          Target: type
          }, (err, session) =>
            if !err
              @session[type] = session
              return resolve session
            else
              return reject err
        )
      )
    )

  getPhoneBook: ->
    #GetPhoneBook
    return new Promise((resolve, reject) =>
      utils.getSessInterface(@, @session.pbap, 'org.bluez.obex.PhonebookAccess1', 'org.bluez.obex')
      .then((iface) =>
        iface.Select('int', 'pb', =>
          iface.PullAll('/tmp/phonebook.vcf', {}, (err, vcard) =>
            if err
              return reject(err)
            utils.getSessInterface(@, vcard[0], 'org.bluez.obex.Transfer1', 'org.bluez.obex')
            .then((iface) ->
              transfer = setInterval(=>
                iface.getProperties((err, pb) =>
                  if err or pb.Status is 'complete'
                    clearInterval(transfer)
                    vCard.parseVcardFile('/tmp/phonebook.vcf', (err, json) =>
                      @phonebook = json
                      return resolve @phonebook
                    )
                  return
                )
                return
              ,500)
              return
            )
            return
          )
          return
        )
        return
      )
      return
    )

  getMessages: (type) ->
    #GetMessages
    return new Promise((resolve, reject) =>
      utils.getSessInterface(@, @session['map'], 'org.bluez.obex.MessageAccess1', 'org.bluez.obex')
      .then((iface) =>
        iface.SetFolder 'telecom/msg', (err, folder) =>
          iface.ListMessages(type, {}, (err, messages) =>
            if !err
              @messages[type] = messages
              return resolve messages
            else
              return reject err
          )
          return
        return
      )
      return
    )

  readMessage: (path) ->
    #GetMessage
    return new Promise((resolve, reject) =>
      utils.getSessInterface(@, path, 'org.bluez.obex.Message1', 'org.bluez.obex')
      .then((msgIface) =>
        msgIface.Get '', true, (err, message) =>
          utils.getSessInterface(@, message[0], 'org.bluez.obex.Transfer1', 'org.bluez.obex')
          .then((iface) ->
            transfer = setInterval(->
              iface.getProperties((err, trans) ->
                if err or trans.Status is 'complete'
                  clearInterval(transfer)
                  msgIface.setProperty('Read', true)
                  vCard.parseVcardFile(message[1].Filename, (err, msg) ->
                    return resolve msg
                  )
                return
              )
              return
            ,500)
            return
          )
          return
        return
      )
      return
    )

  answerCall: (voiceCall) ->
    utils.getInterface(@, voicecCall[0], 'org.ofono.VoiceCall', 'org.ofono').then((iface) =>
      @currentCall = iface
      @currentCall.Answer()
    )

  hangupCall: ->
    if @currentCall
      @currentCall.Hangup()
      @currentCall = null


  # Phony Class to controle audio of a bluetooth device.
  #
  # @param  {string} serviceUUID=0000110b - ServiceUUID to connect to.
  #
  # @return {Phony} Class Instance
  constructor: (serviceUUID) ->
    if serviceUUID
      @SERVICE_UUID = serviceUUID.toLowerCase()
    else
      @SERVICE_UUID = utils.SERVICE_UUIDS.AVRemoteControlTarget
    _bindListeners(@)

    utils.getInterface(@, '/org/bluez/hci0', 'org.bluez.Adapter1')
    .then( (iface) =>
      @adapter = iface
      _registerHandlers(@).then((res) =>
        if res.indexOf(false) is -1
          @setPower(true).then( () =>
            @.emit('ready')
            utils.getInterface(@, '/', 'org.freedesktop.DBus.ObjectManager')
            .then( (iface) =>
              @manager = iface
              @manager.GetManagedObjects((err, objects) =>
                utils.checkForDevice(@, objects)
                utils.getSessInterface(@, '/', 'org.freedesktop.DBus.ObjectManager')
                .then( (iface) =>
                  @sessManager = iface
                  @sessManager.GetManagedObjects((err, objects) ->
                    console.log '########', err, objects
                    return
                  )
                  return
                )
                return
              )
              return
            )
            return
          )
        return
      )
      return
    )
    return

# @message Put the utils to the end so we can use the class variables
utils = require('./utils')(Phony)

module.exports = Phony

# phony = new Phony()
# phony.on('ready', ->
#   phony.setPairable(true)
#   phony.setDiscoverable(true)
# )
#
# phony.on('propertiesChanged', (a) ->
#   console.log a.args[0]
# )
#
# phony.on('deviceFound', (a) ->
#   if a.device.Name.indexOf('Galaxy') isnt -1
#     phony.selectDevice(a).then( ->
#       phony.connectHandsfree().then(null
#         phony.createOBEXSession('pbap').then( ->
#           phony.getPhoneBook()
#         )
#         phony.createOBEXSession('map').then( ->
#           phony.getMessages('inbox').then((msgs) ->
#           )
#         )
#
#       ,console.log)
# #     phony.getMediaPlayer().then((mp) ->
# #       mp.next()
# #       mp.getTrack().then((track) ->
# #         console.log track
# #       )
# #     )
#     )
# )
