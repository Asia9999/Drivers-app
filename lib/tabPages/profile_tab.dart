import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/splashScrean/splash_screan.dart';
import 'package:flutter/material.dart';
class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton (
        child: const Text(
          "Sign Out",
        ),
        onPressed: ()
        {
          fAuth.signOut();
          // send user to home screen
          Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScrean()));

        },
      ),
      );
  }
}
