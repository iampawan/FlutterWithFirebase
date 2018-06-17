import 'package:flutter/material.dart';

class QuotesScreen extends StatefulWidget {
  @override
  _QuotesScreenState createState() => new _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  double db = 0.0;
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: new Text("Quotes"),
      ),
      body: Container(),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.extension),
        isExtended: true,
        onPressed: () => debugPrint('Clicked'),
        notchMargin: 8.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      bottomNavigationBar: new BottomAppBar(
          color: Colors.purple,
          elevation: 5.0,
          hasNotch: true,
          child: new ButtonBar(
            alignment: MainAxisAlignment.start,
            children: <Widget>[],
          )),
    );
  }
}
