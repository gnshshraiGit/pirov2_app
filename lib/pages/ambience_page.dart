import 'dart:convert';
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import  'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:intl/intl.dart';
import '../widgets/ci_chart.dart';

class AmbienceConfig {
  String serviceType; //Important property for angular service initialization
  String sockUrl; // socketIO endpoint for avstreamer
  bool enabled; //Important property for angular service initialization
  String ambientEvent;

  AmbienceConfig(this.serviceType, this.sockUrl, this.enabled, this.ambientEvent);

  AmbienceConfig.fromJson(Map<String, dynamic> json)
      : serviceType = json['serviceType'],
        sockUrl = json['sockUrl'],
        ambientEvent = json['ambientEvent'],
        enabled = json['enabled'];
}

class AmbiencePage extends StatefulWidget {

  final String pageText;
  AmbienceConfig ambienceConfig;
  
  AmbiencePage(this.pageText, this.ambienceConfig);

  @override
  _AmbiencePageState createState() => _AmbiencePageState();
}


class _AmbiencePageState extends State<AmbiencePage> {

   List<CircularStackEntry> pressuredata = <CircularStackEntry>[
                new CircularStackEntry(<CircularSegmentEntry>[
                  new CircularSegmentEntry(0.0, Colors.blue[300]),
                  new CircularSegmentEntry(100.0, Colors.red[100]),
                ],
                rankKey: ''
                )
              ];  
  List<CircularStackEntry> tempdata = <CircularStackEntry>[
                new CircularStackEntry(<CircularSegmentEntry>[
                  new CircularSegmentEntry(0.0, Colors.blue[300]),
                  new CircularSegmentEntry(100.0, Colors.red[100]),
                ],
                rankKey: ''
                )
              ]; 
  List<CircularStackEntry> humiditydata = <CircularStackEntry>[
                new CircularStackEntry(<CircularSegmentEntry>[
                  new CircularSegmentEntry(0.0, Colors.blue[300]),
                  new CircularSegmentEntry(100.0, Colors.red[100]),
                ],
                rankKey: ''
                )
              ]; 

  String currentTemp = "0";
  String currentHumidity = "0";
  String currentPressure = "0";
  SocketIO socketIO;

  var redata;
  final formatter = new NumberFormat("#.##");

  @override
  void initState() {
    super.initState();
    var sockUri = Uri.parse(widget.ambienceConfig.sockUrl);
    socketIO = SocketIOManager().createSocketIO(sockUri.origin, sockUri.path);
    socketIO.init();
    socketIO.connect();
    socketIO.subscribe(widget.ambienceConfig.ambientEvent, (data) {
      setState(() {
        this.redata = json.decode(data);
        this.currentTemp = this.formatter.format(this.redata['pthdata']['temperature_F']);
        this.currentHumidity = this.formatter.format(this.redata['pthdata']['humidity']);
        this.currentPressure = this.formatter.format(this.redata['pthdata']['pressure_inHg']);
        this.humiditydata = <CircularStackEntry>[
            new CircularStackEntry(<CircularSegmentEntry>[
              new CircularSegmentEntry(double.parse(this.currentHumidity), Colors.blue[300]),
              new CircularSegmentEntry(130.0 - double.parse(this.currentHumidity), Colors.purple[100]),
            ],
            rankKey: ''
            )
          ]; 

      this.tempdata = <CircularStackEntry>[
            new CircularStackEntry(<CircularSegmentEntry>[
              new CircularSegmentEntry(double.parse(this.currentTemp), Colors.red[300]),
              new CircularSegmentEntry(130.0 - double.parse(this.currentTemp), Colors.green[100]),
            ],
            rankKey: ''
            )
          ]; 

    this.pressuredata = <CircularStackEntry>[
            new CircularStackEntry(<CircularSegmentEntry>[
              new CircularSegmentEntry(double.parse(this.currentPressure), Colors.deepOrange[300]),
                new CircularSegmentEntry(130.0 - double.parse(this.currentPressure), Colors.orange[100]),
              ],
              rankKey: ''
              )
            ];  
        });
      });
  }

  @override
  void dispose() {
    //this.socketIO.disconnect();
    SocketIOManager().destroySocket(this.socketIO);   
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title: new Text(widget.pageText)),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
            CiChart(
              datalabel: "Temperature F",
              currentvalue: currentTemp,
              data: tempdata
            ),
            CiChart(
              datalabel: "Humidity %",
              currentvalue: currentHumidity,
              data: humiditydata
            ),
            CiChart(
              datalabel: "Pressure Hg",
              currentvalue: currentPressure,
              data: pressuredata
            )
        ]
      )
    );
  }
}

