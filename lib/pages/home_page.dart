import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pirov2_app/blocs/pirov2-app-bloc.dart';
import 'package:pirov2_app/pages/live_page.dart';

import './ambience_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Pirov2AppBloc _appBloc = Pirov2AppBloc();

  @override
  void dispose() {
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(title: new Text("Device Home")),
      drawer: StreamBuilder(
        stream: _appBloc.pirov2StateObservable,
        builder: (context, AsyncSnapshot<Pirov2AppState> snapshot) {
          return getDrawer(snapshot, context);
        }
      ),
      body: new Image.asset("assets/images/illusion.gif", 
         fit: BoxFit.cover,
         height: double.infinity,
         width: double.infinity,
         alignment: Alignment.center
       )
    );
  }


getDrawer(AsyncSnapshot<Pirov2AppState> snapshot, BuildContext context){
  final List<Widget> menuContent = <Widget>[
      new ListTile(
                title: new Text("Main Menu", style: new TextStyle(fontSize: 25.0)),
              ),
              new ListTile(
                title: new Text("Features"),
              ),
              new Divider(),
    ];
    if(checkIsLiveConfigFound(snapshot)){
      menuContent.add(new ListTile(
                leading: new Icon(Icons.wifi),
                title: new Text("Live"),
                onTap: () {
                  List<dynamic> uiCOnfig = json.decode(snapshot?.data?.currentConfig?.uiConfig);
                  dynamic avConfig = uiCOnfig.firstWhere((el) => el['serviceType'] == 'avstreamer', orElse: () => null);
                  dynamic walkyConfig = uiCOnfig.firstWhere((el) => el['serviceType'] == 'walky', orElse: () => null);
                  Navigator.of(context).pop();
                  Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new LivePage("Live", AVStreamerConfig.fromJson(avConfig), walkyConfig: WalkyConfig.fromJson(walkyConfig))));
                }
              ));
      menuContent.add(new Divider());
    }
    if(checkIsAmbienceConfigFound(snapshot)){
      menuContent.add(new ListTile(
              leading: new Icon(Icons.wb_incandescent),
              title: new Text("Ambience"),
              onTap: () {
                List<dynamic> uiCOnfig = json.decode(snapshot?.data?.currentConfig?.uiConfig);
                dynamic ambConfig = uiCOnfig.firstWhere((el) => el['serviceType'] == 'ambient', orElse: () => null);
                Navigator.of(context).pop();
                Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new AmbiencePage("Ambience", AmbienceConfig.fromJson(ambConfig))));
              }
            ));
      menuContent.add(new Divider());
    }
    menuContent.add(new ListTile(
                leading: new Icon(Icons.close),
                title: new Text("Close"),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ));
    return new Drawer(
        child: new ListView(
          children: menuContent
        )
      );
  }

bool checkIsLiveConfigFound(AsyncSnapshot<Pirov2AppState> snapshot) {
    try{
      List<dynamic> uiCOnfig = json.decode(snapshot?.data?.currentConfig?.uiConfig);
      bool result = false;
      if(uiCOnfig != null)
        result = uiCOnfig.any((el) => el['serviceType'] == 'avstreamer' && el['enabled'] == true);
      return result;
    }
    catch(e){
      return false;
    }
  }

bool checkIsAmbienceConfigFound(AsyncSnapshot<Pirov2AppState> snapshot) {
  try{
      List<dynamic> uiCOnfig = json.decode(snapshot?.data?.currentConfig?.uiConfig);
      bool result = false;
      if(uiCOnfig != null)
        result = uiCOnfig.any((el) => el['serviceType'] == 'ambient' && el['enabled'] == true);
      return result;
    }
  catch(e){
      return false;
    }
  }
}


