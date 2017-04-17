DBus = require 'dbus'
name = require('../package.json').name
debug = require('debug')("#{name}:adapter")
Promise = require 'promise'
util = require 'util'
_ = require 'lodash'
{EventEmitter} = require 'events'

class Adapter extends EventEmitter

  bus: DBus.getBus 'system'

  # Bluez Adapter interface
  #
  # @return {Adapter} Class Instance
  constructor: () ->
    self = @
    utils.getInterface(@, '/org/bluez/hci0', 'org.bluez.Adapter1')
    .then( (iface) ->
      iface.getProperties((err, props)->
        for prop of props
          if props.hasOwnProperty(prop)
            lowerCamel = prop.charAt(0).toLowerCase() + prop.substring(1)
            self[lowerCamel] = props[prop]
        return
      )
      func = _.omit(iface, ['serviceName', 'objectPath', 'interfaceName', 'object', 'bus'])
      for prop of func
        if func.hasOwnProperty(prop)
          lowerCamel = prop.charAt(0).toLowerCase() + prop.substring(1)
          self[lowerCamel] = func[prop]

      return
    )
    return

utils = require('./utils')()

adapter = new Adapter()

setTimeout(->
  console.log adapter
, 2000)
