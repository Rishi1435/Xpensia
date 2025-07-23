import 'package:flutter/material.dart';
import 'package:xpensia/screens/stat/chart.dart';

class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Transactions',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),),
            SizedBox(height: 20,),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: MyChart(),
            )
          ],
        )),
    );
  }
}
