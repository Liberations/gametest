import 'package:flutter/material.dart' show Scaffold,AppBar, StatefulWidget, State, BuildContext, Widget;

class TestJsCallPage extends StatefulWidget {
  const TestJsCallPage({super.key});

  @override
  State<TestJsCallPage> createState() => _TestJsCallPageState();
}

class _TestJsCallPageState extends State<TestJsCallPage> {
  @override
  Widget build(BuildContext context) {
    //anroid webview 注册了 js方法如下
    // mWebView.addJavascriptInterface(this, "AndroidNative");
    //@JavascriptInterface
    //public void h5Call(String msg) {}
    return Scaffold(appBar: AppBar(),);
  }
}
