import 'package:drivers_app/tabPages/earning_tab.dart';
import 'package:drivers_app/tabPages/home_tab.dart';
import 'package:drivers_app/tabPages/profile_tab.dart';
import 'package:drivers_app/tabPages/ratings_tab.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';



class MainScreen extends StatefulWidget
{


  @override
  State<MainScreen> createState() => _MainScreenState();
}



class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin
{

  TabController ? tabController;
  int selectIndex =0;





  onItemClicked(int index)
  {
    setState(() {
      selectIndex = index;
      tabController!.index = selectIndex;

    });
  }



  //1st execute
  @override
  void initState() {
    super.initState();
    // 4pages
    tabController = TabController(length: 4, vsync: this);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: tabController,
        children:const [
          HomeTabPage(),
          EarningsTabPage(),
          RatingsTabPage(),
          ProfileTabPage()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const[

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: "Earnings",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: "Ratings",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),

        ],
        unselectedItemColor: Colors.white54,
        selectedItemColor: Colors.white,
        backgroundColor: Colors.purple,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 14),
        showUnselectedLabels: true,
        currentIndex: selectIndex,
        onTap: onItemClicked,
      ),
    );
  }
}
