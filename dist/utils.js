// Generated by CoffeeScript 1.10.0
var Promise, debug, name, service_uuids, signalDebug;

Promise = require('promise');

name = require('../package.json').name;

debug = require('debug')(name + ':utils');

signalDebug = require('debug')(name + ':signal');

service_uuids = {
  ServiceDiscoveryServerID: '00001000-0000-1000-8000-00805F9B34FB',
  BrowseGroupDescriptorID: '00001001-0000-1000-8000-00805F9B34FB',
  PublicBrowseGroup: '00001002-0000-1000-8000-00805F9B34FB',
  SerialPort: '00001101-0000-1000-8000-00805F9B34FB',
  LANAccessUsingPPP: '00001102-0000-1000-8000-00805F9B34FB',
  DialupNetworking: '00001103-0000-1000-8000-00805F9B34FB',
  IrMCSync: '00001104-0000-1000-8000-00805F9B34FB',
  OBEXObjectPush: '00001105-0000-1000-8000-00805F9B34FB',
  OBEXFileTransfer: '00001106-0000-1000-8000-00805F9B34FB',
  IrMCSyncCommand: '00001107-0000-1000-8000-00805F9B34FB',
  Headset: '00001108-0000-1000-8000-00805F9B34FB',
  CordlessTelephony: '00001109-0000-1000-8000-00805F9B34FB',
  AudioSource: '0000110A-0000-1000-8000-00805F9B34FB',
  AudioSink: '0000110B-0000-1000-8000-00805F9B34FB',
  AVRemoteControlTarget: '0000110C-0000-1000-8000-00805F9B34FB',
  AdvancedAudioDistribution: '0000110D-0000-1000-8000-00805F9B34FB',
  AVRemoteControl: '0000110E-0000-1000-8000-00805F9B34FB',
  VideoConferencing: '0000110F-0000-1000-8000-00805F9B34FB',
  Intercom: '00001110-0000-1000-8000-00805F9B34FB',
  Fax: '00001111-0000-1000-8000-00805F9B34FB',
  HeadsetAudioGateway: '00001112-0000-1000-8000-00805F9B34FB',
  WAP: '00001113-0000-1000-8000-00805F9B34FB',
  WAPClient: '00001114-0000-1000-8000-00805F9B34FB',
  PANU: '00001115-0000-1000-8000-00805F9B34FB',
  NAP: '00001116-0000-1000-8000-00805F9B34FB',
  GN: '00001117-0000-1000-8000-00805F9B34FB',
  DirectPrinting: '00001118-0000-1000-8000-00805F9B34FB',
  ReferencePrinting: '00001119-0000-1000-8000-00805F9B34FB',
  Imaging: '0000111A-0000-1000-8000-00805F9B34FB',
  ImagingResponder: '0000111B-0000-1000-8000-00805F9B34FB',
  ImagingAutomaticArchive: '0000111C-0000-1000-8000-00805F9B34FB',
  ImagingReferenceObjects: '0000111D-0000-1000-8000-00805F9B34FB',
  Handsfree: '0000111E-0000-1000-8000-00805F9B34FB',
  HandsfreeAudioGateway: '0000111F-0000-1000-8000-00805F9B34FB',
  DirectPrintingReferenceObjects: '00001120-0000-1000-8000-00805F9B34FB',
  ReflectedUI: '00001121-0000-1000-8000-00805F9B34FB',
  BasicPringing: '00001122-0000-1000-8000-00805F9B34FB',
  PrintingStatus: '00001123-0000-1000-8000-00805F9B34FB',
  HumanInterfaceDevice: '00001124-0000-1000-8000-00805F9B34FB',
  HardcopyCableReplacement: '00001125-0000-1000-8000-00805F9B34FB',
  HCRPrintServiceClas: '00001126-0000-1000-8000-00805F9B34FB',
  HCRScan: '00001127-0000-1000-8000-00805F9B34FB',
  CommonISDNAccess: '00001128-0000-1000-8000-00805F9B34FB',
  VideoConferencingGW: '00001129-0000-1000-8000-00805F9B34FB',
  UDIMT: '0000112A-0000-1000-8000-00805F9B34FB',
  UDITA: '0000112B-0000-1000-8000-00805F9B34FB',
  AudioVideo: '0000112C-0000-1000-8000-00805F9B34FB',
  SIMAccess: '0000112D-0000-1000-8000-00805F9B34FB',
  PnPInformation: '00001200-0000-1000-8000-00805F9B34FB',
  GenericNetworking: '00001201-0000-1000-8000-00805F9B34FB',
  GenericFileTransfer: '00001202-0000-1000-8000-00805F9B34FB',
  GenericAudio: '00001203-0000-1000-8000-00805F9B34FB',
  GenericTelephony: '00001204-0000-1000-8000-00805F9B34FB',
  PhoneBookPSE: '0000112F-0000-1000-8000-00805F9B34FB',
  PhoneBookPBAP: '0000111E-0000-1000-8000-00805F9B34FB',
  MessageAccessServer: '00001132-0000-1000-8000-00805f9b34fb',
  MessageAccessProfile: '00001133-0000-1000-8000-00805f9b34fb',
  MessageAccessNotification: '00001134-0000-1000-8000-00805f9b34fb'
};

module.exports = function(Phony) {
  return {
    SERVICE_UUIDS: service_uuids,
    getServiceNames: function(uuids) {
      var serviceNames;
      if (uuids) {
        serviceNames = [];
        uuids.forEach(function(uuid) {
          Object.keys(service_uuids).forEach(function(service) {
            var o;
            if (service_uuids[service].toLowerCase() === uuid) {
              o = {};
              o[service] = uuid;
              serviceNames.push(o);
            }
          });
        });
        return serviceNames;
      } else {
        return [];
      }
    },
    parseSignal: function(phony, path, iface, signal, args) {
      signalDebug("Received Signal \"" + signal + "\" from " + args[0]);
      signalDebug(args);
      signalDebug(path);
      signalDebug(iface);
      signal = signal.charAt(0).toLowerCase() + signal.substring(1);
      if (args[0] === 'org.bluez.MediaPlayer1' && args[1].hasOwnProperty('Track')) {
        return phony.media.emit('trackChanged', args[1].Track);
      } else {
        if (args.length > 1) {
          args.splice(0, 1);
        }
        return phony.emit(signal, {
          "interface": iface,
          args: args,
          path: path
        });
      }
    },
    registerHandlers: function(phony) {
      debug("Registering handlers...");
      return Promise.all([this.registerHandler(phony, '/org/bluez', 'org.freedesktop.DBus.Properties', phony.adapter), this.registerHandler(phony, '/org/bluez', Phony.BUS_SERVICE + ".Adapter1", phony.adapter), this.registerHandler(phony, '/org/bluez/hci0', Phony.BUS_SERVICE + ".Device1", phony.adapter)]);
    },
    registerHandler: function(phony, path, iface, sigIface, service) {
      if (service == null) {
        service = Phony.BUS_SERVICE;
      }
      return new Promise(function(resolve, reject) {
        debug("Registering new " + iface + " signal handler...");
        return phony.bus.registerSignalHandler(service, path, iface, sigIface, function(err) {
          if (err) {
            debug('ERROR:', err);
          }
          if (!err) {
            debug("Registered " + iface + " signal handler.");
          }
          if (!err) {
            return resolve(true);
          } else {
            return reject(err);
          }
        });
      });
    },
    getInterface: function(phony, path, ifaceName, service) {
      if (service == null) {
        service = Phony.BUS_SERVICE;
      }
      return new Promise((function(_this) {
        return function(resolve, reject) {
          debug("Looking for interface " + ifaceName + "...");
          return phony.bus.getInterface(service, path, ifaceName, function(err, iface) {
            if (err) {
              debug("Error for " + ifaceName, err);
            }
            if (!err) {
              debug("Got interface " + ifaceName);
            }
            if (!err) {
              return _this.registerHandler(phony, path, ifaceName, iface).then(function() {
                return resolve(iface);
              }, function(err) {
                if (err) {
                  debug("Error for " + ifaceName, err);
                }
                return reject(err);
              });
            } else {
              return reject(err);
            }
          });
        };
      })(this));
    },
    getSessInterface: function(phony, path, ifaceName, service) {
      if (service == null) {
        service = Phony.BUS_SERVICE;
      }
      return new Promise((function(_this) {
        return function(resolve, reject) {
          debug("Looking for interface " + ifaceName + "...");
          return phony.sess.getInterface(service, path, ifaceName, function(err, iface) {
            if (err) {
              debug("Error for " + ifaceName, err);
            }
            if (!err) {
              debug("Got interface " + ifaceName);
            }
            if (!err) {
              return _this.registerHandler(phony, path, ifaceName, iface).then(function() {
                return resolve(iface);
              }, function(err) {
                if (err) {
                  debug("Error for " + ifaceName, err);
                }
                return reject(err);
              });
            } else {
              return reject(err);
            }
          });
        };
      })(this));
    },
    checkForDevice: function(self, objects) {
      return Object.keys(objects).forEach(function(object) {
        var deviceMatch, ifaces;
        ifaces = Object.keys(objects[object]);
        deviceMatch = ifaces.join(' ').match(/org\.bluez\.Device\d/);
        if (deviceMatch) {
          debug("Found device interface " + deviceMatch);
        }
        if (deviceMatch && deviceMatch.length > 0) {
          return self.emit('deviceFound', {
            "interface": deviceMatch.toString(),
            device: objects[object][deviceMatch.toString()],
            path: object
          });
        }
      });
    },
    findServiceUUID: function(device) {
      var serviceIndex;
      serviceIndex = device.UUIDs.indexOf(Phony.SERVICE_UUID);
      if (serviceIndex === -1) {
        return false;
      } else {
        return device.UUIDs[serviceIndex];
      }
    },
    checkForPlayer: function(self, objects) {
      var player;
      player = null;
      Object.keys(objects).forEach(function(object) {
        var deviceMatch, ifaces;
        ifaces = Object.keys(objects[object]);
        deviceMatch = ifaces.join(' ').match(/org\.bluez\.MediaPlayer\d/);
        if (deviceMatch) {
          debug("Found media player interface " + deviceMatch);
        }
        if (deviceMatch && deviceMatch.length > 0 && !player) {
          return player = {
            "interface": deviceMatch.toString(),
            device: objects[object][deviceMatch.toString()],
            path: object
          };
        }
      });
      return player;
    }
  };
};

return;
