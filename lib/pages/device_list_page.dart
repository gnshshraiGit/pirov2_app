import 'package:flutter/material.dart';
import 'package:pirov2_app/blocs/pirov2-app-bloc.dart';
import 'package:pirov2_app/pages/home_page.dart';

class DeviceListPage extends StatefulWidget {
  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final Pirov2AppBloc _appBloc = Pirov2AppBloc();

  @override
  void initState() {
    super.initState();
    _appBloc.LoadDevices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController();
    TextEditingController uiconfigController = TextEditingController();
    return Scaffold(
      appBar: new AppBar(title: new Text("Devices")),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(3.0),
            child: FloatingActionButton(
              heroTag: null,
              child: Icon(Icons.refresh, size: 25),
              backgroundColor: Colors.purple[300],
              onPressed: () => _appBloc.RefreshList()
            )
          ),
          Padding(
            padding: EdgeInsets.all(3.0),
            child: FloatingActionButton(
              heroTag: null,
              child: Icon(Icons.add, size: 25),
              backgroundColor: Colors.teal[300],
              onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: nameController,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter Device name';
                                }
                                  return null;
                                },
                              decoration: InputDecoration(
                              labelText: 'Device Name'
                            ))
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: TextFormField(
                              controller: uiconfigController,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return 'Please enter UI Config URL';
                                }
                                  return null;
                                },
                              decoration: InputDecoration(
                              labelText: 'UI Config URL'
                            )),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RaisedButton(
                              child: Text("Add"),
                              onPressed: () {
                                 if (_formKey.currentState.validate()) {
                                    _formKey.currentState.save();
                                     _appBloc.AddDevice(new Pirov2Config(
                                       deviceName: nameController.value.text,
                                       deviceUiServiceURL: uiconfigController.value.text
                                       ));
                                    Navigator.of(context).pop();
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                });
              }
            )
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _appBloc.pirov2StateObservable,
        builder: (context, AsyncSnapshot<Pirov2AppState> snapshot) {
          return deviceList(snapshot);
        }
      )
    );
  }
  Widget deviceList(AsyncSnapshot<Pirov2AppState> snapshot){
    if (snapshot.hasData && snapshot.data.isLoading){
      return new Center(
        child: new CircularProgressIndicator(),
      );
    }
    else if(snapshot.hasData && snapshot.data.configList.length==0){
      return new Center(
        child: new Text("No Device Found", style: TextStyle(fontSize: 25.0)),
      );
    } 
    else{
      return ListView.builder(
          padding: EdgeInsets.all(3.0),
          itemCount: snapshot.data?.configList?.length,
          itemBuilder: (BuildContext ctxt, int index) {
            return Ink(
              decoration: BoxDecoration(
                color: Colors.teal[50],
                border: Border.all(
                  color: Colors.purple[100],
                  width: 0.5,
                )
              ),
              child: new ListTile(
                leading: new Icon(Icons.devices),
                title: Text(snapshot.data?.configList?.elementAt(index)?.deviceName, style: new TextStyle(fontSize: 20.0)),
                onTap: () async {
                  _appBloc.DeviceSelect(index);
                  await Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new HomePage()));
                  _appBloc.RefreshList();
              }
            )
          );
        },
      );
    }
  }
}

