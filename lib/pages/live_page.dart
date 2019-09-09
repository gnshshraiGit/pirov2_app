import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:kostasoft_mjpeg/kostasoft_mjpeg.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AVStreamerConfig {
String serviceType; //Important property for angular service initialization
String sockUrl; // socketIO endpoint for avstreamer
bool enabled; //Important property for angular service initialization
String getRecordingUrl;
String videoUrl;
String audioUrl;
String startRecordEvent;
String recordingDoneEvent;
String recordingErrEvent;

AVStreamerConfig(this.serviceType, this.sockUrl, this.enabled, this.getRecordingUrl, this.videoUrl, this.audioUrl, this.startRecordEvent, this.recordingDoneEvent, this.recordingErrEvent);

AVStreamerConfig.fromJson(Map<String, dynamic> json)
    : serviceType = json['serviceType'],
      sockUrl = json['sockUrl'],
      getRecordingUrl = json['getRecordingUrl'],
      videoUrl = json['videoUrl'],
      audioUrl = json['audioUrl'],
      enabled = json['enabled'],
      startRecordEvent = json['startRecordEvent'],
      recordingDoneEvent = json['recordingDoneEvent'],
      recordingErrEvent = json['recordingErrEvent'];
}

class WalkyConfig {
  String serviceType; //Important property for angular service initialization
  String sockUrl; // socketIO endpoint for avstreamer
  bool enabled; //Important property for angular service initialization
  String goFwdEvent;
  String goBkdEvent;
  String goLftEvent;
  String goRitEvent;
  String stopEvent;
  String servingEvent;
  String blockDetectEvent;

  WalkyConfig(this.serviceType, this.sockUrl, this.enabled, this.goFwdEvent, this.goBkdEvent, this.goLftEvent, this.goRitEvent, this.stopEvent, this.servingEvent, this.blockDetectEvent);

  WalkyConfig.fromJson(Map<String, dynamic> json)
      : serviceType = json['serviceType'],
        sockUrl = json['sockUrl'],
        enabled = json['enabled'],
        goFwdEvent = json['goFwdEvent'],
        goBkdEvent = json['goBkdEvent'],
        goLftEvent = json['goLftEvent'],
        goRitEvent = json['goRitEvent'],
        stopEvent = json['stopEvent'],
        servingEvent = json['servingEvent'],
        blockDetectEvent = json['blockDetectEvent'];
        
}

class RecordingData{
  String filename;
  bool isRecording = false;
  bool isDownloadAvailable = false;

  RecordingData({this.filename, this.isRecording, this.isDownloadAvailable});
}

class LivePage extends StatefulWidget {
  @override
  _LivePageState createState() => _LivePageState();

  String pageText;
  AVStreamerConfig avConfig;
  WalkyConfig walkyConfig;

  LivePage(this.pageText, this.avConfig, {this.walkyConfig});
}

class _LivePageState extends State<LivePage> {
  SocketIO socketAvIO;
  SocketIO socketWalkyIO;
  RecordingData rdData;
  bool doLoadPageComponents;
  Timer recordButtonTimer;

  @override
  void initState() {
    super.initState();
    this.doLoadPageComponents = false;
    rdData = RecordingData(
      filename: "",
      isRecording: false,
      isDownloadAvailable: false
    );

    if(widget.walkyConfig!=null && widget.walkyConfig.enabled){
      var walkySockUri = Uri.parse(widget.walkyConfig.sockUrl);
      socketWalkyIO = SocketIOManager().createSocketIO(walkySockUri.origin, walkySockUri.path);
      socketWalkyIO.init();
      socketWalkyIO.connect();
    }
 
    var avSockUri = Uri.parse(widget.avConfig.sockUrl);
    socketAvIO = SocketIOManager().createSocketIO(avSockUri.origin, avSockUri.path);
    socketAvIO.init();
    //wait 5 sec before loading page components so that give time to ffserver to get ready
    socketAvIO.connect().timeout(Duration(seconds: 5), onTimeout: (){
      setState(() {
       this.doLoadPageComponents = true; 
      });
    });

    socketAvIO.subscribe(widget.avConfig.recordingErrEvent, (data){
      var jsonData = json.decode(data);
      rdData.isRecording = jsonData["success"] && jsonData["recording"];
      var msg = rdData.isRecording ? 'Recording Started' : 'Error Occured';
      openRecordingErrNotification(msg);
    });
    
    socketAvIO.subscribe(widget.avConfig.recordingDoneEvent, (data){
      var jsonData = json.decode(data);
      setState(() {
        rdData = RecordingData(
          filename: jsonData["filename"],
          isRecording: false,
          isDownloadAvailable: true
        );
      });
      openRecordingErrNotification("Recording is ready to download");

      //To cancel previous timer
      if(recordButtonTimer != null){
        recordButtonTimer.cancel();
      }

      //To start new timer for record button show duration
      recordButtonTimer = Timer(Duration(minutes: 9), () => {
        setState(() {
          rdData = RecordingData(
            filename: "",
            isRecording: false,
            isDownloadAvailable: false
          );
      })
    });
  });
}

  @override
  void dispose() {
    try{
      //this.socketWalkyIO.disconnect();
      //this.socketAvIO.disconnect();
      SocketIOManager().destroySocket(this.socketWalkyIO); 
      SocketIOManager().destroySocket(this.socketAvIO); 
      super.dispose();
    }
    catch(e){

    }
  }

  @override
  Widget build(BuildContext context) {
    if(!this.doLoadPageComponents){
      return new Center(
        child: new CircularProgressIndicator(),
      );
    }
    return Scaffold(
      appBar: new AppBar(title: new Text(widget.pageText)),
      body: Container(
        child: Column(
          children: getPageWidgets()
        )
      )
    );
  }

  List<Widget> getPageWidgets(){
    List<Widget> lstWidgets = new List<Widget>();
    if(widget.avConfig.enabled){
      lstWidgets.add(getVideoTile());
    }
    if(widget.walkyConfig!=null && widget.walkyConfig.enabled){
      lstWidgets.add(getWalkyControls());
    }
    return lstWidgets;
  }

  Widget getVideoTile(){
    double vidTileHeight = 0.7;
    if(!widget.walkyConfig.enabled){
      vidTileHeight= 0.87; //Trial and error values
    }
    return SizedBox(
      height: MediaQuery.of(context).size.height * vidTileHeight,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
              MjpegView(
                url: widget.avConfig.videoUrl + "?from=81237", 
                isFullscreen: true
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: getVideoTileControls()
            )
          ]
        )
    );
  }

  List<Widget> getVideoTileControls(){
    var vidControls = <Widget>[
        FloatingActionButton(
          heroTag: null,
          child: Icon(Icons.videocam, size: 25),
          mini: true,
          backgroundColor: Theme.of(context).errorColor,
          onPressed: () {
            socketAvIO.sendMessage(widget.avConfig.startRecordEvent, "{}");
            setState(() {
             rdData = new RecordingData(
              isRecording: true,
              isDownloadAvailable: false,
              filename: ""
             ); 
            });
            rdData.isRecording = true;
          },
        )
    ];

    if(rdData.isDownloadAvailable){
      vidControls.add(FloatingActionButton(
          heroTag: null,
          child: Icon(Icons.cloud_download, size: 25),
          mini: true,
          backgroundColor: Theme.of(context).accentColor,
          onPressed: () async {
            await DownloadsPathProvider.downloadsDirectory.then((Directory dir) async {       
              PermissionStatus permissionResult = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
              if(permissionResult != PermissionStatus.granted){
                await PermissionHandler().requestPermissions([PermissionGroup.storage]);
                permissionResult = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
              }
              if(permissionResult == PermissionStatus.granted){
                // code of read or write file in external storage (SD card)
                Dio dio = Dio();
                dio.download(widget.avConfig.getRecordingUrl + rdData.filename, dir.path + "/" + rdData.filename).then((_){
                  openRecordingErrNotification("Download Completed");
                }).catchError((err){
                  print(err);
                  openRecordingErrNotification("Download Error occured");
                });
              }  
            });
          },
        )
      );
    }
    return vidControls;
  } 

  Widget getWalkyControls(){
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.17,
      width: MediaQuery.of(context).size.width,
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.3,
              child:  GestureDetector(
                child: FlatButton(
                  child: Icon(Icons.arrow_back, size: 50)
                ),
                onTapDown: (TapDownDetails dts) {
                  socketWalkyIO.sendMessage(widget.walkyConfig.goLftEvent, "{}");
                },
                onTapUp: (TapUpDetails dts) {
                  socketWalkyIO.sendMessage(widget.walkyConfig.stopEvent, "{}");
                }
              )
            ) ,
            Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                SizedBox(
                width:  MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.085,
                child:  GestureDetector(
                  child: FlatButton(
                    child: Icon(Icons.arrow_upward, size: 50)
                    ),
                    onTapDown: (TapDownDetails dts) {
                      socketWalkyIO.sendMessage(widget.walkyConfig.goFwdEvent, "{}");
                    },
                    onTapUp: (TapUpDetails dts) {
                      socketWalkyIO.sendMessage(widget.walkyConfig.stopEvent, "{}");
                    }
                  )
                ),
                SizedBox(
                  width:  MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.085,
                  child:  GestureDetector(
                    child: FlatButton(
                      child: Icon(Icons.arrow_downward, size: 50)
                      ),
                      onTapDown: (TapDownDetails dts) {
                        socketWalkyIO.sendMessage(widget.walkyConfig.goBkdEvent, "{}");
                      },
                      onTapUp: (TapUpDetails dts) {
                        socketWalkyIO.sendMessage(widget.walkyConfig.stopEvent, "{}");
                      }
                    )
                  )
                ],
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,  
                child:  GestureDetector(
                  child: FlatButton(
                    child: Icon(Icons.arrow_forward, size: 50)
                    ),
                    onTapDown: (TapDownDetails dts) {
                      socketWalkyIO.sendMessage(widget.walkyConfig.goRitEvent, "{}");
                    },
                    onTapUp: (TapUpDetails dts) {
                      socketWalkyIO.sendMessage(widget.walkyConfig.stopEvent, "{}");
                    }
                  )
                )
              ],
            )
          )
        );
    }

   openRecordingErrNotification(String message){
     Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 5,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }
}