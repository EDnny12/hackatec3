import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hackatec2/principal.dart';
import 'package:provider/provider.dart';
import 'package:hackatec2/providers/usuario.dart';
class SelectBondedDevicePage extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not avaliable, they would be disabled from the selection.
  final bool checkAvailability;

  const SelectBondedDevicePage({this.checkAvailability = true});

  @override
  _SelectBondedDevicePage createState() => new _SelectBondedDevicePage();
}

enum _DeviceAvailability {
  no,
  maybe,
  yes,
}

class _DeviceWithAvailability extends BluetoothDevice {
  BluetoothDevice device;
  _DeviceAvailability availability;
  int rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectBondedDevicePage extends State<SelectBondedDevicePage> {
  List<_DeviceWithAvailability> devices = List<_DeviceWithAvailability>();

  // Availability
  StreamSubscription<BluetoothDiscoveryResult> _discoveryStreamSubscription;
  bool _isDiscovering;

  _SelectBondedDevicePage();

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    // Setup a list of the bonded devices
    FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices.map(
                (device) => _DeviceWithAvailability(device, widget.checkAvailability ? _DeviceAvailability.maybe : _DeviceAvailability.yes)
        ).toList();
      });
    });
  }

  void _restartDiscovery() {
    setState(() {
      _isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        Iterator i = devices.iterator;
        while (i.moveNext()) {
          var _device = i.current;
          if (_device.device == r.device) {
            _device.availability = _DeviceAvailability.yes;
            _device.rssi = r.rssi;
          }
        }
      });
    });

    _discoveryStreamSubscription.onDone(() {
      setState(() { _isDiscovering = false; });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    // _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<BluetoothDeviceListEntry> list = devices.map((_device) => BluetoothDeviceListEntry(
      device: _device.device,
      rssi: _device.rssi,
      enabled: _device.availability == _DeviceAvailability.yes,
      onTap: ()async {


        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => Provider.of<Usuario>(context).root? Dashboard(_device.device):User(_device.device)),
        );

      },
    )).toList();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          title: Text('Dispositivo',style: TextStyle(color: Colors.red),),
          actions: <Widget>[
            (
                _isDiscovering ?
                FittedBox(child: Container(
                    margin: new EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.red))
                ))
                    :
                IconButton(
                    icon: Icon(Icons.replay,color: Colors.red,),
                    onPressed: _restartDiscovery
                )
            )
          ],
        ),
        body: ListView(children: list)
    );
  }
}
class BluetoothDeviceListEntry extends ListTile {
  BluetoothDeviceListEntry({
    @required BluetoothDevice device,
    int rssi,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    bool enabled = true
  }) : super(
    onTap: onTap,
    onLongPress: onLongPress,
    enabled: enabled,
    leading: Icon(Icons.devices), // @TODO . !BluetoothClass! class aware icon
    title: Text(device.name ?? "Unknown device"),
    subtitle: Text(device.address.toString()),
    trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          rssi != null ? Container(
            margin: new EdgeInsets.all(8.0),
            child: DefaultTextStyle(
                style: () {
                  /**/ if (rssi >= -35) return TextStyle(color: Colors.greenAccent[700]);
                  else if (rssi >= -45) return TextStyle(color: Color.lerp(Colors.greenAccent[700], Colors.lightGreen,        -(rssi + 35) / 10));
                  else if (rssi >= -55) return TextStyle(color: Color.lerp(Colors.lightGreen,       Colors.lime[600],         -(rssi + 45) / 10));
                  else if (rssi >= -65) return TextStyle(color: Color.lerp(Colors.lime[600],        Colors.amber,             -(rssi + 55) / 10));
                  else if (rssi >= -75) return TextStyle(color: Color.lerp(Colors.amber,            Colors.deepOrangeAccent,  -(rssi + 65) / 10));
                  else if (rssi >= -85) return TextStyle(color: Color.lerp(Colors.deepOrangeAccent, Colors.redAccent,         -(rssi + 75) / 10));
                  else /*code symetry*/ return TextStyle(color: Colors.redAccent);
                } (),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(rssi.toString()),
                      Text('dBm'),
                    ]
                )
            ),
          ) : Container(width: 0, height: 0),
          device.isConnected ? Icon(Icons.import_export) : Container(width: 0, height: 0),
          device.isBonded ? Icon(Icons.link) : Container(width: 0, height: 0),
        ]
    ),
  );
}
