import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:upnp/upnp.dart';

class Pirov2Config {
  String deviceName;
  String deviceUiServiceURL;
  var uiConfig; 
  Pirov2Config({this.deviceName, this.deviceUiServiceURL, this.uiConfig});
}

class Pirov2AppState {
  bool isLoading = false;
  String bgImageUrl;
  Pirov2Config currentConfig;
  List<Pirov2Config> configList;
  Pirov2AppState({this.configList, this.currentConfig});
}

class Pirov2AppBloc {

  Pirov2AppState pirov2AppState = Pirov2AppState(
    configList: List<Pirov2Config>(),
    currentConfig: null
  );

  BehaviorSubject<Pirov2AppState> _subjectPirov2AppState;

  //This will make it global singleton
  static final Pirov2AppBloc pirov2AppBloc = Pirov2AppBloc._();

  Pirov2AppBloc._(){
   _subjectPirov2AppState = new BehaviorSubject<Pirov2AppState>.seeded(this.pirov2AppState); //initializes the subject with element already
  }

  factory Pirov2AppBloc() {
     return pirov2AppBloc;
   }

  //this observable keeps track of the state
  Observable<Pirov2AppState> get pirov2StateObservable => _subjectPirov2AppState.stream; 

  //events
  void LoadDevices() async {
    var devDisco = DeviceDiscoverer();
    pirov2AppState.isLoading = true;
    _subjectPirov2AppState.sink.add(pirov2AppState);
    await devDisco.quickDiscoverClients(query: "pirov2", unique: false).listen((DiscoveredClient dev) {
      pirov2AppState.isLoading = false;
      pirov2AppState.configList.add(new Pirov2Config(
        deviceName: dev.usn,
        deviceUiServiceURL: dev.location
      ));
      _subjectPirov2AppState.sink.add(pirov2AppState);
    }).asFuture()
    .timeout(Duration(seconds: 5), onTimeout: (){
      pirov2AppState.isLoading = false;
      _subjectPirov2AppState.sink.add(pirov2AppState);
    }).catchError((err){
      _subjectPirov2AppState.sink.add(pirov2AppState);
      print(err);
    });
  }

  void AddDevice(Pirov2Config evntData){
    pirov2AppState.configList.add(evntData);
    _subjectPirov2AppState.sink.add(pirov2AppState);
  }

  void DeviceSelect (int deviceIndex) async {
      pirov2AppState.currentConfig = pirov2AppState.configList.elementAt(deviceIndex);
      var response = await http.get(pirov2AppState.currentConfig.deviceUiServiceURL);
      if (response.statusCode == 200) {
        pirov2AppState.currentConfig.uiConfig = response.body;
      } else {
        pirov2AppState.configList.removeAt(deviceIndex); // bad device remove from list
        print("Request failed with status: ${response.statusCode}.");
      }
       _subjectPirov2AppState.sink.add(pirov2AppState);
  }

  void RefreshList () async {
      pirov2AppState.currentConfig = null;
      pirov2AppState.configList= List<Pirov2Config>();
      LoadDevices();
  }

  void dispose(){
    _subjectPirov2AppState.close();
  }
  
}
