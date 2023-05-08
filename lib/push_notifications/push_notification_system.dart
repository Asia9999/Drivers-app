import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../global/global.dart';
class PushNotificationSystem
{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging( ) async
  {
    //1. Terminated
    //When the app is completely closed and opened directly from the push notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        //display ride request information - user information who request a ride
        //readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });
    //2. Foreground
    //When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage)
    {
      //display ride request information - user information who request a ride
      //readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage)
    {
      //display ride request information - user information who request a ride
     // readUserRideRequestInformation(remoteMessage!.data["rideRequestId"], context);
    });
  }
  Future generateAndGetToken() async
  {
    String? registrationToken = await messaging.getToken();
       print("FCM Registration Token: ");
       print(registrationToken);

    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}

