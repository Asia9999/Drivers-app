import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/splashScrean/splash_screan.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CarInfoScreen extends StatefulWidget
{

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen>
{
  TextEditingController carModelTextEditingController = TextEditingController();
  TextEditingController carNumberTextEditingController = TextEditingController();
  TextEditingController carColorTextEditingController = TextEditingController();
  List<String> carTypesList = ["car-3seats","car-6seats","car-9seats"];
  String ? selectedCarType;

  saveCarInfo()
  {
    Map driverCarInfoMap =
    {
      "car_color" :carColorTextEditingController.text.trim(),
      "car_number": carNumberTextEditingController.text.trim(),
      "car_model" :carModelTextEditingController.text.trim(),
      "type":selectedCarType,
    };

    DatabaseReference driverRef =  FirebaseDatabase.instance.ref().child("drivers");
    driverRef.child(currentFirebaseUser!.uid).child("car_details").set(driverCarInfoMap);

    Fluttertoast.showToast(msg: "Car info has been saved, Congratulation.");
    Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScrean()));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child :Padding(
        padding :const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 24,),

            Padding(
              padding :const EdgeInsets.all(20.0),
              child: Image.asset("images/Logo.jpeg"),
            ) ,

            const SizedBox(height: 10,),
            const Text(
              "Write Car Details",
              style :TextStyle(
                fontSize: 26,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),

            TextField(
              controller: carModelTextEditingController,
              style: const TextStyle(
                  color: Colors.grey
              ),
              decoration: const InputDecoration(
                labelText: "Car Model",
                hintText: "Car Model",
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
              controller: carNumberTextEditingController,
              style: const TextStyle(
                  color: Colors.grey
              ),
              decoration: const InputDecoration(
                labelText: "Car Number",
                hintText: "Car Number",
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
              controller: carColorTextEditingController,
              style: const TextStyle(
                  color: Colors.grey
              ),
              decoration: const InputDecoration(
                labelText: "Car Color",
                hintText: "Car Color",
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
            const SizedBox(height: 10,),
            DropdownButton(
              iconSize: 26,
              dropdownColor: Colors.white,
              hint:const Text(
                "Please choose car type",
                  style: TextStyle (
                  fontSize: 14.0,
                color: Colors.grey,

              ),
              ),
              value: selectedCarType,
              onChanged: (newValue){
                setState(() {
                  selectedCarType = newValue.toString();
                });
              },
              items: carTypesList.map((car){
                return DropdownMenuItem(
                  child: Text(
                    car,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  value: car,
                );
              }).toList(),
            ),

            const SizedBox(height: 20,),

            ElevatedButton(
              onPressed: ()
              {
                  if(carColorTextEditingController.text.isNotEmpty
                      && carNumberTextEditingController.text.isNotEmpty
                      && carModelTextEditingController.text.isNotEmpty
                  &&selectedCarType !=null)
                    {
                      saveCarInfo();
                    }
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.purpleAccent,
              ),
              child: const Text(
                "Save Now",
                style: TextStyle(
                  color: Colors.white,
                  fontSize:18,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
