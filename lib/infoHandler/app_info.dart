import 'dart:async';
import 'dart:developer';
import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivers_app/main.dart';
import 'package:drivers_app/models/directions.dart';
import 'package:drivers_app/models/ticket.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../assistants/assistant_methods.dart';
import '../global/global.dart';
import '../models/user_ride_request_information.dart';
import '../widgets/fare_amount_collection_dialog.dart';
import '../widgets/progress_dialog.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation, userDropOffLocation;
  Ticket? existTicket;
  String? ticketID;
  UserRideRequestInformation? userRideRequestDetails;
  Passenger? currentPassenger;
  Widget ticketInfoWidget = Container();

  GoogleMapController? newTripGoogleMapController;
  final Completer<GoogleMapController> controllerGoogleMap = Completer();

  static const CameraPosition kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";
  Color? buttonColor = Colors.green;

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircle = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polyLinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDriverCurrentPosition;

  String rideRequestStatus = "accepted";

  String durationFromOriginToDestination = "";

  bool isRequestDirectionDetails = false;

  Ticket? ticket;
  String? timeToArrive;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _ticketSnapshot;

  initialize(UserRideRequestInformation? userRideRequestInfo) {
    userRideRequestDetails = userRideRequestInfo;
    saveAssignedDriverDetailsToUserRideRequest();
    createDriverIconMarker();
    notifyListeners();
  }

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions dropOffAddress) {
    userDropOffLocation = dropOffAddress;
    notifyListeners();
  }

  drawPolyLineFromOriginToDestination(
      LatLng originLatLng, LatLng destinationLatLng) async {
    var directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);

    print("These are points = ");
    print(directionDetailsInfo!.e_points);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo!.e_points!);

    polyLinePositionCoordinates.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        polyLinePositionCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setOfPolyline.clear();

    Polyline polyline = Polyline(
      color: Colors.purpleAccent,
      polylineId: const PolylineId("PolylineID"),
      jointType: JointType.round,
      points: polyLinePositionCoordinates,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      geodesic: true,
    );

    setOfPolyline.add(polyline);

    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newTripGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );

    setOfMarkers.add(originMarker);
    setOfMarkers.add(destinationMarker);

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.purple,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.pink,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setOfCircle.add(originCircle);
    setOfCircle.add(destinationCircle);

    notifyListeners();
  }

  createDriverIconMarker() {
    if (iconAnimatedMarker == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(
          navigatorKey.currentContext!,
          size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_icon.png")
          .then((value) {
        iconAnimatedMarker = value;
      });
    }
  }

  updatePassengersIconOnMap() {
    if (ticket!.passengers!.isNotEmpty) {
      controllerGoogleMap.future.then((value) {
        ticket!.passengers!.forEach((passenger) {
          if (passenger.isPickedUp == true) {
            return;
          }
          Marker passengerMarker = Marker(
            markerId: MarkerId(passenger.name),
            position:
                LatLng(passenger.origin!.latitude, passenger.origin!.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: passenger.name, snippet: "Passenger"),
          );
          setOfMarkers.add(passengerMarker);
          value.showMarkerInfoWindow(MarkerId(ticket!.passengers!.first.id));
        });
      });
    }

    notifyListeners();
  }

  getDriversLocationUpdatesAtRealTime() {
    LatLng oldLatLng = LatLng(0, 0);
    streamSubscriptionDriverLivePosition =
        Geolocator.getPositionStream().listen((Position position) {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      Marker animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: const InfoWindow(title: "This is your Position"),
      );

      CameraPosition cameraPosition =
          CameraPosition(target: latLngLiveDriverPosition, zoom: 16);
      newTripGoogleMapController!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      setOfMarkers
          .removeWhere((element) => element.markerId.value == "AnimatedMarker");
      setOfMarkers.add(animatingMarker);

      oldLatLng = latLngLiveDriverPosition;
      updateDurationTimeAtRealTime();

      //updating driver location at real time in Database
      Map driverLatLngDataMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };
      FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(userRideRequestDetails!.rideRequestId!)
          .child("driverLocation")
          .set(driverLatLngDataMap);
    });
  }

  updateDurationTimeAtRealTime() async {
    if (isRequestDirectionDetails == false) {
      isRequestDirectionDetails = true;

      if (onlineDriverCurrentPosition == null) {
        return;
      }

      var originLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      ); //Driver current Location

      var destinationLatLng;

      if (rideRequestStatus == "accepted") {
        destinationLatLng =
            userRideRequestDetails!.originLatLng; //user PickUp Location
      } else {
        destinationLatLng =
            userRideRequestDetails!.destinationLatLng; //user DropOff Location
      }

      var directionInformation =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
              originLatLng, destinationLatLng);

      if (directionInformation != null) {
        durationFromOriginToDestination = directionInformation.duration_text!;
      }

      isRequestDirectionDetails = false;
    }

    notifyListeners();
  }

  endTripNow() async {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(
        message: "Please wait...",
      ),
    );

    //get the tripDirectionDetails = distance travelled
    var currentDriverPositionLatLng = LatLng(
      onlineDriverCurrentPosition!.latitude,
      onlineDriverCurrentPosition!.longitude,
    );
    var tripDirectionDetails =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            currentDriverPositionLatLng, userRideRequestDetails!.originLatLng!);
    //fare amount
    double totalFareAmount =
        AssistantMethods.calculateFareAmountFromOriginToDestination(
            tripDirectionDetails!);

    FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(userRideRequestDetails!.rideRequestId!)
        .child("fareAmount")
        .set(totalFareAmount.toString());

    FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(userRideRequestDetails!.rideRequestId!)
        .child("status")
        .set("ended");

    streamSubscriptionDriverLivePosition!.cancel();

    Navigator.pop(navigatorKey.currentContext!);

    //display fare amount in dialog box
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext c) => FareAmountCollectionDialog(
        totalFareAmount: totalFareAmount,
      ),
    );
    //save fare amount to driver total earnings
    saveFareAmountToDriverEarnings(totalFareAmount);
  }

  saveFareAmountToDriverEarnings(double totalFareAmount) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) //earnings sub Child exists
      {
        double oldEarnings = double.parse(snap.snapshot.value.toString());
        double driverTotalEarnings = totalFareAmount + oldEarnings;

        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(driverTotalEarnings.toString());
      } else //earnings sub Child do not exists
      {
        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(totalFareAmount.toString());
      }
    });
  }

  saveAssignedDriverDetailsToUserRideRequest() {
    DatabaseReference databaseReference = FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(userRideRequestDetails!.rideRequestId!);

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };
    databaseReference.child("driverLocation").set(driverLocationDataMap);

    databaseReference.child("status").set("accepted");
    databaseReference.child("driverId").set(onlineDriverData.id);
    databaseReference.child("driverName").set(onlineDriverData.name);
    databaseReference.child("driverPhone").set(onlineDriverData.phone);
    databaseReference.child("car_details").set(
        onlineDriverData.car_color.toString() +
            onlineDriverData.car_model.toString());

    saveRideRequestIdToDriverHistory();
  }

  saveRideRequestIdToDriverHistory() {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("tripsHistory");

    tripsHistoryRef.child(userRideRequestDetails!.rideRequestId!).set(true);
  }

  // Ticket Stuff

  acceptTicket(Ticket ticket) async {
    existTicket = ticket;

    await FirebaseFirestore.instance
        .collection("Tickets")
        .doc(ticket.id)
        .update({
      "driverLocation": GeoPoint(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude),
    });
    startTimerTicket();
    updatePassengersIconOnMap();
    subscribeToTicket(ticket);

    notifyListeners();
  }

  subscribeToTicket(Ticket tick) {
    try {
      _ticketSnapshot = FirebaseFirestore.instance
          .collection('Tickets')
          .doc(tick.id)
          .snapshots()
          .listen((event) async {
        log("event: ${event.data()}");
        if (event.data() != null) {
          var data = event.data()!;
          existTicket = Ticket.fromMap(data, event.id);

          if (existTicket!.status == "Pending") {
            // showWaitingResponseFromDriverUI();
          } else if (existTicket!.status == 'collecting') {
            updatePassengersIconOnMap();
            showUIForCollectingTicket();

            // showOtherPassengersOnMap();
            // showUIForAssignedDriverInfo();
          } else if (existTicket!.status == 'started') {
            updateReachingTimeToUserDropOffLocation(LatLng(
                ticket!.driverLocation!.latitude,
                ticket!.driverLocation!.longitude));
            showUIForStartedTicket();
            // showUIForStartedTrip();
          } else if (existTicket!.status == "Cancelled") {
            // showUICancelledTicket();

            cancelTicket(existTicket!);
            Fluttertoast.showToast(
                msg: "The ticket is cancelled",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.purple,
                textColor: Colors.white,
                fontSize: 16.0);
          }
          notifyListeners();
        }
      });
    } on Exception catch (e) {
      log(e.toString());

      // ticketInfoWidget = Positioned(
      //   child: Container(
      //     child: Text("No Ticket Found .. something went wrong /n $e "),
      //   ),
      // );
      notifyListeners();
      // TODO
    }
  }

  /// UI Stuff

  showUIForCollectingTicket() {
    ticketInfoWidget = Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white30,
              blurRadius: 18,
              spreadRadius: .5,
              offset: Offset(0.6, 0.6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: ListView.builder(
                    itemBuilder: (context, i) {
                      return Row(
                        children: [
                          Text(ticket!.passengers![i].name),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                //call driver

                                // launch("tel://" + ticketDriver!.phone);
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Colors.purple,
                              ),
                              icon: const Icon(
                                Icons.phone_android,
                                color: Colors.white,
                                size: 22,
                              ),
                              label: const Text(
                                "Call",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          ticket!.passengers![i].isPickedUp
                              ? Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      //cancel ticket
                                      // resignFromTicket();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.purple,
                                    ),
                                    icon: const Icon(
                                      Icons.pin_drop,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      "Picked Up",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      pickUpPassenger(ticket!.passengers![i]);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.purple,
                                    ),
                                    icon: const Icon(
                                      Icons.pin_drop,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    label: const Text(
                                      "Pick Up",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                    itemCount: ticket!.passengers!.length,
                  )),

              const SizedBox(
                height: 18,
              ),

              const Divider(
                thickness: 2,
                height: 2,
                color: Colors.grey,
              ),

              const SizedBox(
                height: 8,
              ),

              //user name - icon
              Row(
                children: [
                  Text(
                    userRideRequestDetails!.userName!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreenAccent,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              //user PickUp Address with icon
              Row(
                children: [
                  Image.asset(
                    "images/origin.png",
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child: Container(
                      child: Text(
                        userRideRequestDetails!.originAddress!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              //user DropOff Address with icon
              Row(
                children: [
                  Image.asset(
                    "images/destination.png",
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  Expanded(
                    child: Container(
                      child: Text(
                        userRideRequestDetails!.destinationAddress!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              const Divider(
                thickness: 2,
                height: 2,
                color: Colors.grey,
              ),

              const SizedBox(height: 10.0),

              ElevatedButton.icon(
                onPressed: () async {
                  //[driver has arrived at user PickUp Location] - Arrived Button
                  if (rideRequestStatus == "accepted") {
                    rideRequestStatus = "arrived";

                    FirebaseDatabase.instance
                        .ref()
                        .child("All Ride Requests")
                        .child(userRideRequestDetails!.rideRequestId!)
                        .child("status")
                        .set(rideRequestStatus);

                    buttonTitle = "Let's Go"; //start the trip
                    buttonColor = Colors.lightGreen;

                    showDialog(
                      context: navigatorKey.currentContext!,
                      barrierDismissible: false,
                      builder: (BuildContext c) => ProgressDialog(
                        message: "Loading...",
                      ),
                    );

                    await drawPolyLineFromOriginToDestination(
                        userRideRequestDetails!.originLatLng!,
                        userRideRequestDetails!.destinationLatLng!);

                    Navigator.pop(navigatorKey.currentContext!);
                  }
                  //[user has already sit in driver's car. Driver start trip now] - Lets Go Button
                  else if (rideRequestStatus == "arrived") {
                    rideRequestStatus = "ontrip";

                    FirebaseDatabase.instance
                        .ref()
                        .child("All Ride Requests")
                        .child(userRideRequestDetails!.rideRequestId!)
                        .child("status")
                        .set(rideRequestStatus);

                    buttonTitle = "End Trip"; //end the trip
                    buttonColor = Colors.redAccent;
                  }
                  //[user/Driver reached to the dropOff Destination Location] - End Trip Button
                  else if (rideRequestStatus == "ontrip") {
                    endTripNow();
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: buttonColor,
                ),
                icon: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: 25,
                ),
                label: Text(
                  buttonTitle!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showUIForStartedTicket() {
    ticketInfoWidget = Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white30,
                  blurRadius: 18,
                  spreadRadius: .5,
                  offset: Offset(0.6, 0.6),
                ),
              ],
            ),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(children: [
                  //duration
                  Text(
                    durationFromOriginToDestination,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightGreenAccent,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Divider(
                    thickness: 2,
                    height: 2,
                    color: Colors.grey,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  //user name - icon
                  Row(
                    children: [
                      Text(
                        userRideRequestDetails!.userName!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.phone_android,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  //user PickUp Address with icon
                  Row(
                    children: [
                      Image.asset(
                        "images/origin.png",
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Container(
                          child: Text(
                            userRideRequestDetails!.originAddress!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20.0),

                  //user DropOff Address with icon
                  Row(children: [
                    Image.asset(
                      "images/destination.png",
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Container(
                        child: Text(
                          userRideRequestDetails!.destinationAddress!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  ])
                ]))));
  }

  ///

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (ticket != null) {
      var dropOffLocation = userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation!.locationLongitude!);

      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userDestinationPosition,
      );

      if (directionDetailsInfo == null) {
        return;
      }

      timeToArrive = "Arrive in :: $timeToArrive ";

      notifyListeners();
    }
  }

  void unSubscribeToTicket() {
    _ticketSnapshot?.cancel();
  }

  void updateTicket(Ticket ticket) {
    existTicket = ticket;
    FirebaseFirestore.instance
        .collection("Tickets")
        .doc(ticket.id)
        .update(ticket.toMap());
    notifyListeners();
  }

  void cancelTicket(Ticket ticket) {
    ticket.status = "Cancelled";
    FirebaseFirestore.instance
        .collection("Tickets")
        .doc(ticket.id)
        .update(ticket.toMap());
    notifyListeners();
  }

  pickUpPassenger(Passenger passenger) {
    passenger.isPickedUp = true;
    updateTicket(ticket!);
    notifyListeners();
  }

  startTimerTicket() {
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (ticket == null || ticket!.timer == 0) {
        timer.cancel();
        return;
      }
      if (ticket!.status == "collecting") {
        
        List p = [];
        List? pp;

        if (ticket!.passengers!.isEmpty || ticket!.passengers == null) {
          cancelTicket(ticket!);
          timer.cancel();
          return;
        }

        if (timer.tick == 15) {
          ticket!.status = "started";
          updateTicket(ticket!);
          timer.cancel();
          return;
        }
      } else if (ticket!.status == "started") {
        ticket!.acceptNewPassenger = false;
        updateTicket(ticket!);
        timer.cancel();
        return;
      }
      timerDown();
    });
  }

  timerDown() {
    FirebaseFirestore.instance.collection("Tickets").doc(ticket!.id).update({
      "timer": FieldValue.increment(-1),
    });
  }

  void updateArrivalTimeToUserPickupLocation(LatLng latLng) {
    if (userRideRequestDetails != null) {
      var originLatLng = latLng; //Driver current Location

      var destinationLatLng = userRideRequestDetails!.originLatLng!;

      AssistantMethods.obtainOriginToDestinationDirectionDetails(
              originLatLng, destinationLatLng)
          .then((directionDetails) {
        if (directionDetails != null) {
          durationFromOriginToDestination = directionDetails.duration_text!;
          notifyListeners();
        }
      });
    }
  }
}
