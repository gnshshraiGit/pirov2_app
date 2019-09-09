import 'package:flutter/material.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';


class CiChart extends StatelessWidget {
  GlobalKey<AnimatedCircularChartState> keychart = new GlobalKey<AnimatedCircularChartState>();
  String datalabel = "init";
  String currentvalue = "init";
  List<CircularStackEntry> data;  

  CiChart({this.datalabel, this.currentvalue, this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
          AnimatedCircularChart(
          key: keychart,
          percentageValues: true,
          holeLabel: currentvalue,
          size: Size(MediaQuery.of(context).size.width * 0.3, MediaQuery.of(context).size.height * 0.2),
          initialChartData: data,
          chartType: CircularChartType.Radial
          ),
          Text(
            datalabel,
            style: TextStyle(
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.bold,
              fontSize: 15.0,
            )
          )
      ],
    );
  }
}