import 'dart:async';

import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/infoHandler/app_info.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/widgets/fare_amount_collection_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../assistants/assistant_methods.dart';

import '../models/ticket.dart';
import '../widgets/progress_dialog.dart';

class NewTripScreen extends StatefulWidget {
  UserRideRequestInformation? userRideRequestDetails;

  NewTripScreen({
    this.userRideRequestDetails,
  });

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  //Step 1:: when driver accepts the user ride request
  // originLatLng = driverCurrent Location
  // destinationLatLng = user PickUp Location

  //Step 2:: driver already picked up the user in his/her car
  // originLatLng = user PickUp Location => driver current Location
  // destinationLatLng = user DropOff Location

  @override
  void initState() {
    super.initState();

    Provider.of<AppInfo>(context, listen: false)
        .initialize(widget.userRideRequestDetails!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppInfo>(
      builder: (context, value, child) => Scaffold(
        body: Stack(
          children: [
            //google map
            GoogleMap(
              padding: EdgeInsets.only(bottom: value.mapPadding),
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: AppInfo.kGooglePlex,
              markers: value.setOfMarkers,
              circles: value.setOfCircle,
              polylines: value.setOfPolyline,
              onMapCreated: (GoogleMapController controller) {
                value.controllerGoogleMap.complete(controller);
                value.newTripGoogleMapController = controller;

                value.mapPadding = 350;

                var driverCurrentLatLng = LatLng(
                    driverCurrentPosition!.latitude,
                    driverCurrentPosition!.longitude);

                var userPickUpLatLng =
                    widget.userRideRequestDetails!.originLatLng;

                value.drawPolyLineFromOriginToDestination(
                    driverCurrentLatLng, userPickUpLatLng!);

                value.getDriversLocationUpdatesAtRealTime();
              },
            ),

            value.ticketInfoWidget

            //ui
          ],
        ),
      ),
    );
  }
}
