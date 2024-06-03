import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_logging/sentry_logging.dart';

final dio = Dio();
final log = Logger('MyAwesomeLogger');

void main() async {
  await SentryFlutter.init(
        (options) {
      options.dsn = 'https://c8cae4a6f8f442b0ebcf92d655fbf244@o4507236624695296.ingest.us.sentry.io/4507236626530304';
      //options.release = '$packageName@$version+$buildNumber';
      options.enablePrintBreadcrumbs = false;
      options.tracesSampleRate = 1;
      options.tracesSampler = (samplingContext) {
        return 1;
      };
      options.addIntegration(LoggingIntegration());
    },
    appRunner:() async {
      initApp();
    },
  );
}

void _initDio() {
  dio.addSentry();
}

void initApp() {
  final character = {
    'name': 'Mighty Fighter',
    'age': 19,
    'attack_type': 'melee',
  };
  Sentry.configureScope((scope) => scope.setContexts('character', character));
  Sentry.configureScope(
        (scope) => scope.setUser(SentryUser(id: '1234', email: 'jane.doe@example.com')),
  );
  _initDio();
  final transaction = Sentry.startTransaction("start", "collection");
  transaction.setMeasurement("second", 2);
  runApp(const MyApp());
  transaction.setMeasurement("third", 3);

  final innerSpan = transaction.startChild('task1', description: 'operation');
  log.info("2");
  innerSpan.setData("orderId2", "222");
  innerSpan.finish();

  final innerSpan2 = transaction.startChild('task2', description: 'operation');
  log.info("2");
  innerSpan2.setData("orderId2", "222");
  innerSpan2.finish();

  final innerSpan3 = transaction.startChild('task3', description: 'operation');
  log.info("2");
  innerSpan3.setData("orderId2", "222");
  innerSpan3.finish();

  transaction.finish();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      navigatorObservers: [
        SentryNavigatorObserver(),
      ],
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() async {
    log.info('start!');
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
    final transaction = Sentry.startTransaction(
      'dio-web-request',
      'request',
      bindToScope: true,
    );
    final span = transaction.startChild(
      'dio',
      description: 'desc',
    );
    await Sentry.captureMessage('Something went wrong');
    log.info('end!');
    Response<String>? response;
    try {
      response = await dio.get<String>('https://baidu.com');
      span.status = const SpanStatus.ok();
    } catch (exception, stackTrace) {
      span.throwable = exception;
      span.status = const SpanStatus.internalError();
      await Sentry.captureException(exception, stackTrace: stackTrace);
    } finally {
      await span.finish();
    }
    await transaction.finish();
    throw Exception("name can not null");
  }

  @override
  Widget build(BuildContext context) {
    log.info('build!');
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Text('click me'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class MyApp2 extends StatelessWidget {
  const MyApp2({
    Key? key,
  }) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('App Crashing Example'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
