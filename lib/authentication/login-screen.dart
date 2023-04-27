import 'package:drivers_app/authentication/signup_screen.dart';
import 'package:drivers_app/splashScrean/splash_screan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../global/global.dart';
import '../widgets/progress_dialog.dart';


class LoginScreen extends StatefulWidget
{

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen>
{
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  validateFrom()
  {
    if (!emailTextEditingController.text.contains("@")) {
      Fluttertoast.showToast(msg: "Email address is not Valid.");
    }

    else if (passwordTextEditingController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Password is required.");
    }
    else
    {
      loginDriverNow();
    }
  }
  loginDriverNow() async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext c)
        {
          return ProgressDialog(message:"Processing, Please wait...",);

        }
    );
    //firebase
    final User? firebaseUser =(
        await fAuth.signInWithEmailAndPassword(
          email: emailTextEditingController.text.trim(),
          //for count the extra space
          password: passwordTextEditingController.text.trim(),
        ).catchError((msg)
        {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Error" + msg.toString());

        })
    ).user;
    if(firebaseUser != null)
    {
      //to check if driver exist
      DatabaseReference driverRef =  FirebaseDatabase.instance.ref().child("drivers");
      driverRef.child(firebaseUser.uid).once().then((driverKey)
      {
         final snap = driverKey.snapshot;
         if(snap.value != null)
           {
             currentFirebaseUser = firebaseUser;
             Fluttertoast.showToast(msg: "Login Successful.");
             Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScrean()));
           }
         else
           {
             Fluttertoast.showToast(msg: "No record exist with this email.");
             fAuth.signOut();
             Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScrean()));

           }
      });


    }
    else
    {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error occurred during Login");

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30,),
              Padding(
                padding :const EdgeInsets.all(20.0),
                child: Image.asset("images/Logo.jpeg"),
              ) ,
              const SizedBox(height: 10,),
              const Text(
                "Login as a Driver",
                style :TextStyle(
                  fontSize: 26,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: emailTextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    color: Colors.grey
                ),
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "Email",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),

                ),
              ),
              TextField(
                controller: passwordTextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: const TextStyle(
                    color: Colors.grey
                ),
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Password",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),

                ),
              ),

              const SizedBox(height: 20,),
              ElevatedButton(
                onPressed: ()
                {
                    validateFrom();
                    },
                style: ElevatedButton.styleFrom(
                  primary: Colors.purpleAccent,
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:18,
                  ),
                ),
              ),

              TextButton(
                child: const Text(
                  "Already don't have an account? Register here",
                  style: TextStyle(color: Colors.grey) ,
                ),
                onPressed: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=>SignUpScreen()));

                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
