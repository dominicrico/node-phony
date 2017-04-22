// Generated by CoffeeScript 1.10.0
(function() {
  var DBus, EventEmitter, Phony, Promise, debug, mpDebug, name, util, utils, vCard,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  DBus = require('dbus');

  name = require('../package.json').name;

  debug = require('debug')(name + ":core");

  mpDebug = require('debug')(name + ":mediaPlayer");

  Promise = require('promise');

  util = require('util');

  EventEmitter = require('events').EventEmitter;

  vCard = require('vcard-json');

  Phony = (function(superClass) {
    var _bindListeners, _registerHandlers, _setDiscovery, _setProperty, mediaPlayerControls;

    extend(Phony, superClass);

    Phony.SERVICE_UUID = null;

    Phony.BUS_SERVICE = 'org.bluez';

    Phony.prototype.bus = DBus.getBus('system');

    Phony.prototype.sess = DBus.getBus('session');

    Phony.prototype.session = {};

    Phony.prototype.adapter = null;

    Phony.prototype.manager = null;

    Phony.prototype.sessManager = null;

    Phony.prototype.device = null;

    Phony.prototype.media = null;

    Phony.prototype.modem = null;

    Phony.prototype.phonebook = null;

    Phony.prototype.messages = {};

    Phony.prototype.currentCall = null;

    _bindListeners = function(self) {
      self.bus.on('signal', function(bus, sender, path, iface, signal, args) {
        return utils.parseSignal(self, path, iface, signal, args);
      });
    };

    _registerHandlers = function(self) {
      return utils.registerHandlers(self);
    };

    _setProperty = function(self, prop, state) {
      debug("Set " + prop + " to " + state + "...");
      return new Promise(function(resolve, reject) {
        return self.adapter.setProperty(prop, state, function(err) {
          if (!err) {
            debug(prop + " is now " + state + ".");
            return resolve(state);
          } else {
            return reject(err);
          }
        });
      });
    };

    _setDiscovery = function(self, state) {
      var next;
      return new Promise(function(resolve, reject) {
        if (state !== false) {
          debug("Started discovering...");
          return self.adapter.startDiscovery(next);
        } else {
          debug("Stopped discovering.");
          return self.adapter.stopDiscovery(next);
        }
      }, next = function(err) {
        if (!err) {
          return resolve(state);
        } else {
          return reject(err);
        }
      });
    };

    Phony.prototype.registerHandler = function(path, iface, signalInterface) {
      return utils.registerHandler(this, path, iface, signalInterface);
    };

    Phony.prototype.setPower = function(state) {
      return _setProperty(this, 'Powered', state);
    };

    Phony.prototype.setPairable = function(state) {
      return _setProperty(this, 'Pairable', state);
    };

    Phony.prototype.setDiscoverable = function(state) {
      return _setProperty(this, 'Discoverable', state);
    };

    Phony.prototype.discovery = function(state) {
      return _setDiscovery(this, state);
    };

    Phony.prototype.selectDevice = function(device) {
      debug("Selecting device \"" + device.device.Name + "\"");
      debug("Available Services:", utils.getServiceNames(device.device.UUIDs));
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return utils.getInterface(_this, device.path, device["interface"]).then(function(iface) {
            _this.device = iface;
            _this.device.setProperty('Trusted', true);
            if (device.device.Connected !== true) {
              debug("Trying to connect to \"" + device.device.Name + "\"");
              _this.device.Connect(function(err) {
                if (err) {
                  debug("Error while connecting: " + err);
                  return reject(err);
                } else {
                  debug("Connection to \"" + device.device.Name + "\" established");
                  return resolve(true);
                }
              });
            } else {
              debug("Already connected with \"" + device.device.Name + "\"");
              return resolve(true);
            }
          });
        };
      })(this));
    };

    Phony.prototype.getMediaPlayer = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          _this.manager.GetManagedObjects(function(err, objects) {
            var player;
            player = utils.checkForPlayer(_this, objects);
            utils.getInterface(_this, player.path, player["interface"]).then(function(iface) {
              _this.media = iface;
              debug("Connected to Media Player");
              return resolve(mediaPlayerControls(_this.media));
            });
          });
        };
      })(this));
    };

    mediaPlayerControls = function(player) {
      return {
        play: function() {
          mpDebug('play');
          return player.Play();
        },
        pause: function() {
          mpDebug('pause');
          return player.Pause();
        },
        stop: function() {
          mpDebug('stop');
          return player.Stop();
        },
        next: function() {
          mpDebug('next track');
          return player.Next();
        },
        prev: function() {
          mpDebug('prev track');
          return player.Previous();
        },
        shuffle: function(type) {
          mpDebug("shuffle \"" + type + "\"");
          if (['off', 'alltracks', 'group'].indexOf(type) !== -1) {
            return player.Shuffle(type);
          } else {
            return player.Shuffle('off');
          }
        },
        repeat: function(type) {
          mpDebug("shuffle \"" + type + "\"");
          if (['off', 'singletrack', 'alltracks', 'group'].indexOf(type) !== -1) {
            return player.Repeat(type);
          } else {
            return player.Repeat('off');
          }
        },
        getTrack: function() {
          mpDebug('track info');
          return new Promise(function(resolve, reject) {
            player.getProperty('Track', function(err, track) {
              if (err) {
                return reject(err);
              } else {
                return resolve(track);
              }
            });
          });
        }
      };
    };

    Phony.prototype.connectHandsfree = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return _this.device.ConnectProfile(utils.SERVICE_UUIDS.Handsfree, function(err, profile) {
            if (err) {
              debug('Can not connect to Handsfree Service');
              return reject(err);
            }
            return _this.device.ConnectProfile(utils.SERVICE_UUIDS.PhoneBookPBAP, function(err, pb) {
              if (err) {
                debug('Can not connect to Phonebook PBAP');
                return reject(err);
              }
              return _this.device.ConnectProfile(utils.SERVICE_UUIDS.SerialPort, function(err, port) {
                if (err) {
                  debug('Can not connect to SerialPort');
                  return reject(err);
                }
                return _this.device.ConnectProfile(utils.SERVICE_UUIDS.AdvancedAudioDistribution, function(err, obex) {
                  if (err) {
                    debug('Can not connect to Audio');
                    return reject(err);
                  }
                  return _this.device.ConnectProfile(utils.SERVICE_UUIDS.SIMAccess, function(err, sim) {
                    if (err) {
                      debug('Can not connect to Phonebook PBAP');
                      return reject(err);
                    } else {
                      debug('Handsfree, Sim Access, SMS and Phonebook Profiles connected');
                      return resolve(true);
                    }
                  });
                });
              });
            });
          });
        };
      })(this));
    };

    Phony.prototype.createOBEXSession = function(type) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          return utils.getSessInterface(_this, '/org/bluez/obex', 'org.bluez.obex.Client1', 'org.bluez.obex').then(function(iface) {
            return iface.CreateSession('84:2E:27:03:10:5D', {
              Target: type
            }, function(err, session) {
              if (!err) {
                _this.session[type] = session;
                return resolve(session);
              } else {
                return reject(err);
              }
            });
          });
        };
      })(this));
    };

    Phony.prototype.getPhoneBook = function() {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          utils.getSessInterface(_this, _this.session.pbap, 'org.bluez.obex.PhonebookAccess1', 'org.bluez.obex').then(function(iface) {
            iface.Select('int', 'pb', function() {
              iface.PullAll('/tmp/phonebook.vcf', {}, function(err, vcard) {
                if (err) {
                  return reject(err);
                }
                utils.getSessInterface(_this, vcard[0], 'org.bluez.obex.Transfer1', 'org.bluez.obex').then(function(iface) {
                  var transfer;
                  transfer = setInterval((function(_this) {
                    return function() {
                      iface.getProperties(function(err, pb) {
                        if (err || pb.Status === 'complete') {
                          clearInterval(transfer);
                          vCard.parseVcardFile('/tmp/phonebook.vcf', function(err, json) {
                            _this.phonebook = json;
                            return resolve(_this.phonebook);
                          });
                        }
                      });
                    };
                  })(this), 500);
                });
              });
            });
          });
        };
      })(this));
    };

    Phony.prototype.getMessages = function(type) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          utils.getSessInterface(_this, _this.session['map'], 'org.bluez.obex.MessageAccess1', 'org.bluez.obex').then(function(iface) {
            iface.SetFolder('telecom/msg', function(err, folder) {
              iface.ListMessages(type, {}, function(err, messages) {
                if (!err) {
                  _this.messages[type] = messages;
                  return resolve(messages);
                } else {
                  return reject(err);
                }
              });
            });
          });
        };
      })(this));
    };

    Phony.prototype.readMessage = function(path) {
      return new Promise((function(_this) {
        return function(resolve, reject) {
          utils.getSessInterface(_this, path, 'org.bluez.obex.Message1', 'org.bluez.obex').then(function(msgIface) {
            msgIface.Get('', true, function(err, message) {
              utils.getSessInterface(_this, message[0], 'org.bluez.obex.Transfer1', 'org.bluez.obex').then(function(iface) {
                var transfer;
                transfer = setInterval(function() {
                  iface.getProperties(function(err, trans) {
                    if (err || trans.Status === 'complete') {
                      clearInterval(transfer);
                      msgIface.setProperty('Read', true);
                      vCard.parseVcardFile(message[1].Filename, function(err, msg) {
                        return resolve(msg);
                      });
                    }
                  });
                }, 500);
              });
            });
          });
        };
      })(this));
    };

    Phony.prototype.answerCall = function(voiceCall) {
      return utils.getInterface(this, voicecCall[0], 'org.ofono.VoiceCall', 'org.ofono').then((function(_this) {
        return function(iface) {
          _this.currentCall = iface;
          return _this.currentCall.Answer();
        };
      })(this));
    };

    Phony.prototype.hangupCall = function() {
      if (this.currentCall) {
        this.currentCall.Hangup();
        return this.currentCall = null;
      }
    };

    function Phony(serviceUUID) {
      if (serviceUUID) {
        this.SERVICE_UUID = serviceUUID.toLowerCase();
      } else {
        this.SERVICE_UUID = utils.SERVICE_UUIDS.AVRemoteControlTarget;
      }
      _bindListeners(this);
      utils.getInterface(this, '/org/bluez/hci0', 'org.bluez.Adapter1').then((function(_this) {
        return function(iface) {
          _this.adapter = iface;
          _registerHandlers(_this).then(function(res) {
            if (res.indexOf(false) === -1) {
              _this.setPower(true).then(function() {
                _this.emit('ready');
                utils.getInterface(_this, '/', 'org.freedesktop.DBus.ObjectManager').then(function(iface) {
                  _this.manager = iface;
                  _this.manager.GetManagedObjects(function(err, objects) {
                    utils.checkForDevice(_this, objects);
                    utils.getSessInterface(_this, '/', 'org.freedesktop.DBus.ObjectManager').then(function(iface) {
                      _this.sessManager = iface;
                      _this.sessManager.GetManagedObjects(function(err, objects) {
                        console.log('########', err, objects);
                      });
                    });
                  });
                });
              });
            }
          });
        };
      })(this));
      return;
    }

    return Phony;

  })(EventEmitter);

  utils = require('./utils')(Phony);

}).call(this);
