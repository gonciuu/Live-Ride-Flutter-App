import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../helpers/snack_helper.dart';
import '../models/trip.dart';
import '../helpers/location_helper.dart';
import '../models/lat_lng.dart';

class RideScreen extends StatefulWidget {
  @override
  _RideScreenState createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> with TickerProviderStateMixin {
  AnimationController _animationController;
  AnimationController _endAnimationController;
  Animation<double> _endTripAnimation;
  final _locationStream = LocationHelper.getCurrentLocation();

  final Trip _trip = Trip(
      startTime: DateTime.now(),
      isStart: false,
      altitude: 0.0,
      averageSpeed: 0.0,
      calories: 0,
      distance: 0.0,
      maxSpeed: 0.0,
      coordinatesList: [],
      duration: 0);

  Timer _timer;

  @override
  void initState() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));

    _endAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));

    _endTripAnimation =
        Tween<double>(begin: 0, end: 1).animate(_endAnimationController)
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              SnackHelper.showContentSnack("FINISHED", context);

              /// Tu będzie koniec tripu
              _trip.endTime = DateTime.now();
            }
          });

    _checkPermissions();
    _listenLocationChanges();
    super.initState();
  }

  //----------------| Check Location Permissions---------------------
  Future<void> _checkPermissions() async {
    await LocationHelper.checkPermissions(context);
    setState(() {});
  }

  //===================================================================

  //------------------------| Start / Stop Trip |-----------------------------
  void _startStopTrip() {
    setState(() => _trip.isStart = !_trip.isStart);

    if (_trip.isStart)
      _startDuration();
    else
      _timer.cancel();

    SnackHelper.showContentSnack(
        _trip.isStart ? "Trip started" : "Trip stopped", context);
    _trip.isStart
        ? _animationController.forward()
        : _animationController.reverse();
  }

  //==========================================================================

  //-----------------| Start Duration Timer |----------------------
  void _startDuration() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() => _trip.duration += 1);
    });
  }

  //=================================================================

  void _listenLocationChanges() {
    _locationStream.listen((Position position) {
      if (_trip.isStart) {
        setState(() {
          _trip.coordinatesList
              .add(LatLng(position.latitude, position.longitude));
          _trip.addDistance();
          if (position.speed * 3.6 > _trip.maxSpeed)
            _trip.maxSpeed = position.speed * 3.6;
          _trip.calculateAverageSpeed(position.speed * 3.6);
          _trip.calculateCalories();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return StreamBuilder<Position>(
      stream: _locationStream,
      builder: (context, snapshot) => Scaffold(
        body: snapshot.hasData
            ? SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        child: Text(
                          "Your Trip",
                          style: theme.textTheme.headline4.copyWith(
                              color: Colors.grey.shade900, fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        padding: const EdgeInsets.only(top: 25),
                        width: double.infinity),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70.0),
                      child: Divider(
                        thickness: 3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 60,
                        ),
                        Text(
                          "GPS",
                          style: theme.textTheme.headline6,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Icon(
                          Icons.signal_cellular_alt,
                          color: Colors.red,
                        )
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    FittedBox(
                        child: Text(
                      _trip.isStart
                          ? (snapshot.data.speed * 3.6).toStringAsFixed(1)
                          : "0.0",
                      style: TextStyle(
                          fontSize: 120,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -5,
                          height: 1),
                    )),
                    Text(
                      "km/h",
                      style: theme.textTheme.headline6,
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text((_trip.distance / 1000).toStringAsFixed(2),
                                    style: theme.textTheme.headline4
                                        .copyWith(height: 1)),
                                Text("kilometers",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                FittedBox(
                                  child: Text(
                                      _trip.refactoredDuration.toString(),
                                      style: theme.textTheme.headline4
                                          .copyWith(height: 1)),
                                ),
                                Text("Duration",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(_trip.averageSpeed.toStringAsFixed(1),
                                    style: theme.textTheme.headline4
                                        .copyWith(height: 1)),
                                Text("avg. speed",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(_trip.calories.toString(),
                                    style: theme.textTheme.headline4
                                        .copyWith(height: 1)),
                                Text("calories",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                FittedBox(
                                  child: Text(
                                      _trip.isStart
                                          ? snapshot.data.altitude
                                              .toStringAsFixed(1)
                                          : "300.0",
                                      style: theme.textTheme.headline4
                                          .copyWith(height: 1)),
                                ),
                                Text("altitude",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(_trip.maxSpeed.toStringAsFixed(1),
                                    style: theme.textTheme.headline4
                                        .copyWith(height: 1)),
                                Text("max speed",
                                    style: theme.textTheme.headline5
                                        .copyWith(height: 1)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.only(bottom: 35),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'View Map',
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              icon: Icon(
                                Icons.location_on_rounded,
                                color: Colors.grey.shade900,
                              ),
                              iconSize: 35,
                              onPressed: () {},
                            )),
                        Container(
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.only(bottom: 55),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'Start Trip',
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.play_pause,
                                progress: _animationController,
                                color: Colors.white,
                              ),
                              iconSize: 50,
                              onPressed: _startStopTrip,
                            )),
                        GestureDetector(
                          onLongPressUp: () => !_trip.isStart
                              ? _endAnimationController.reverse()
                              : null,
                          onLongPress: () => !_trip.isStart
                              ? _endAnimationController.forward()
                              : SnackHelper.showContentSnack(
                                  "Cannot end trip when trip is already started. Stop first trip!",
                                  context,
                                  2500),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                  width: 68,
                                  height: 68,
                                  padding: const EdgeInsets.all(7),
                                  margin: const EdgeInsets.only(bottom: 35),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    icon: Icon(
                                      Icons.stop_sharp,
                                    ),
                                    disabledColor: Colors.grey[500],
                                    color: Colors.red,
                                    iconSize: 35,
                                    onPressed: !_trip.isStart ? () {} : null,
                                  )),
                              SizedBox(
                                height: 68,
                                width: 68,
                                child: CircularProgressIndicator(
                                  value: _endTripAnimation.value,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            : Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _endAnimationController.dispose();
    super.dispose();
  }
}
