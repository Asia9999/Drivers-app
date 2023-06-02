import 'dart:developer';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivers_app/main.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../global/global.dart';
import '../models/ticket.dart';
import '../models/user_ride_request_information.dart';
import 'notification_dialog_box.dart';

class PushNotificationSystem extends ChangeNotifier {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async {
    //1. Terminated
    //When the app is completely closed and opened directly from the push notification
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        log(remoteMessage.data.toString());

        //display ride request information - user information who request a ride
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"],
            remoteMessage.data["ticketID"], context);
      }
    });
    //2. Foreground
    //When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      log(remoteMessage!.data.toString());
      //display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"],
          remoteMessage.data["ticketID"], context);
    });

    //3. Background
    //when the app is in the background and opened directly from the push notification.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
      //display ride request information - user information who request a ride
      readUserRideRequestInformation(remoteMessage!.data["rideRequestId"],
          remoteMessage.data["ticketID"], context);
    });
  }

  Future<Ticket> readTicketDetails(String ticketID) async {
    Ticket? ticket;
    try {
      await FirebaseFirestore.instance
          .collection("Tickets")
          .doc(ticketID)
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.exists) {
          ticket = Ticket.fromMap(snapshot.data()!, snapshot.id);
        }
      });
      return ticket!;
    } on Exception catch (e) {
      log(e.toString());
      return ticket!;
    }
  }

  readUserRideRequestInformation(
      String userRideRequestId, String ticketID, BuildContext context) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Requests")
        .child(userRideRequestId)
        .once()
        .then((snapData) async {
      if (snapData.snapshot.value != null) {
        audioPlayer.open(Audio("music/music_notification.mp3"));
        audioPlayer.play();

        double originLat = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["latitude"]);
        double originLng = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["longitude"]);
        String originAddress =
            (snapData.snapshot.value! as Map)["originAddress"];

        double destinationLat = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["latitude"]);
        double destinationLng = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["longitude"]);
        String destinationAddress =
            (snapData.snapshot.value! as Map)["destinationAddress"];

        String userName = (snapData.snapshot.value! as Map)["userName"];
        String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

        String? rideRequestId = snapData.snapshot.key;

        UserRideRequestInformation userRideRequestDetails =
            UserRideRequestInformation();

        userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
        userRideRequestDetails.originAddress = originAddress;

        userRideRequestDetails.destinationLatLng =
            LatLng(destinationLat, destinationLng);
        userRideRequestDetails.destinationAddress = destinationAddress;

        userRideRequestDetails.userName = userName;
        userRideRequestDetails.userPhone = userPhone;

        userRideRequestDetails.rideRequestId = rideRequestId;
        log(ticketID);
        userRideRequestDetails.ticket = await readTicketDetails(ticketID);

        showDialog(
          context: navigatorKey.currentContext!,
          builder: (BuildContext context) => NotificationDialogBox(
            userRideRequestDetails: userRideRequestDetails,
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "This Ride Request Id do not exists.");
      }
    });
  }

  Future generateAndGetToken() async {
    String? registrationToken = await messaging.getToken();
    print("FCM Registration Token: ");
    print(registrationToken);

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}
