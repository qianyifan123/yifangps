import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart'; // Added qyf
import 'package:firebase_database/firebase_database.dart'; // Added qyf
import 'package:cloud_firestore/cloud_firestore.dart';

double Pos_Latitude = 0;
double Pos_Longtitude = 0;

//CollectionReference users = FirebaseFirestore.instance.collection('users'); //qqqqqq
final databaseReference = FirebaseDatabase.instance.reference(); //qqqq
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase qyf
  runApp(const MyApp());
}

//map
Map<String, List<List<double>>> locationData = {
  'FC1': [
    [1.34665, 103.68593, 37],
  ],
  'FC2': [
    [1.34841, 103.68560, 41],
  ],
  'FC9': [
    [1.35236, 103.68554, 35],
  ],
  'FC11': [
    [1.35495, 103.68641, 26],
  ],
  'FC14': [
    [1.35301, 103.68209, 25],
  ],
  'FC16': [
    [1.35035, 103.68137, 57],
  ],
  'NIE': [
    [1.34859, 103.67748, 50],
    [1.34850, 103.67737, 50],
    [1.34852, 103.67728, 50],
  ],
  'Tama': [
    [1.35515, 103.68521, 22],
  ],
  'North Hill': [
    [1.35465, 103.68801, 22],
  ],
  'North Spine': [
    [1.34711, 103.68023, 50],
    [1.34703, 103.68004, 50],
    [1.34700, 103.67984, 50],
  ],
  'Pioneer': [
    [1.34598, 103.68850, 24],
  ],
  'Quad': [
    [1.34476, 103.67985, 54],
  ],
  'South Spine': [
    [1.34244, 103.6823, 46],
  ],
};

//map
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LocationApp(),
    );
  }
}

class LocationApp extends StatefulWidget {
  const LocationApp({Key? key}) : super(key: key);

  @override
  State<LocationApp> createState() => _LocationAppState();
}

class _LocationAppState extends State<LocationApp> {
  final databaseReference = FirebaseDatabase.instance.reference(); // Added
  var locationMessage = "";
  Timer? _locationTimer; // timer 60 secs

  //timer functionlllllllllllllllllllll
  void startLocationCheck() {
    // If a timer is already running, cancel it
    _locationTimer?.cancel();

    // Start a new timer
    _locationTimer = Timer.periodic(Duration(seconds: 60), (timer) async {
      await geofenceCheck();
    });
  }

  //timer functionlllllllllllllllllllllllllll
// [Added] initState method
  @override
  void initState() {
    super.initState();
    startLocationCheck();
  } // [End of Added Code]

  // [Added] dispose method
  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  } // [End of Added Code]

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationMessage = "Location permissions are denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationMessage =
              "Location permissions are permanently denied and cannot be requested again.";
        });
        return;
      }

      var position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      Pos_Latitude = position.latitude;
      Pos_Longtitude = position.longitude;
      setState(() {
        locationMessage = "${position.latitude} , ${position.longitude}";
      });

      var lastposition = await Geolocator.getLastKnownPosition();
      print(lastposition);
      uploadLocationToFirebase(
          position.latitude, position.longitude); //jjjjjjjjjjjjjjjj
      //incrementCounter(); //jjjjjjjjjjjjjjjjjjj
      geofenceCheck();
    } catch (e) {
      print(e);
      setState(() {
        locationMessage = "Error: ${e.toString()}";
      });
    }
  }

//added qyf
  Future<void> uploadLocationToFirebase(
      double latitude, double longitude) async {
    try {
      //Create a reference to your Firestore collection.
      final CollectionReference locationCollection = FirebaseFirestore.instance
          .collection(
              'users'); // Replace 'locations' with your Firestore collection name.

      // Upload the latitude and longitude to Firestore.
      await locationCollection.add({
        'latitude': latitude,
        'longitude': longitude,
      });

      print(
          "Location data uploaded to Firestore: Latitude $latitude, Longitude $longitude");
    } catch (e) {
      print("Error uploading location data to Firestore: ${e.toString()}");
    }
  }

// added qyf
//counter function
  // Future<void> incrementCounter() async {
  //   try {
  //     // Reference to the Firestore collection and document where 'counter' is stored.
  //     CollectionReference counterCollection =
  //         FirebaseFirestore.instance.collection('counter');
  //     DocumentReference counterDoc =
  //         counterCollection.doc('RbWOWZ3qxbg4xqTIxECv');

  //     // Use a transaction to increment the counter safely.
  //     await FirebaseFirestore.instance.runTransaction((transaction) async {
  //       DocumentSnapshot counterSnapshot = await transaction.get(counterDoc);

  //       if (counterSnapshot.exists) {
  //         // If the document exists, increment the 'counter' field.
  //         int currentCounter = counterSnapshot['counter'] ?? 0;
  //         currentCounter++;
  //         transaction.update(counterDoc, {'counter': currentCounter});
  //         print('Counter incremented to $currentCounter');
  //       } else {
  //         // If the document doesn't exist, create it with 'counter' set to 1.
  //         transaction.set(counterDoc, {'counter': 1});
  //         print('Counter initialized to 1');
  //       }
  //     });
  //   } catch (e) {
  //     print('Error incrementing counter: ${e.toString()}');
  //   }
  // }
// [New] Function to increment counter for specific canteen new stuff
  Future<void> incrementCounterForCanteen(String canteenName) async {
    try {
      // Reference to the Firestore 'canteens' collection.
      CollectionReference canteensCollection =
          FirebaseFirestore.instance.collection('canteens');
      DocumentReference canteenDoc = canteensCollection.doc(canteenName);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot canteenSnapshot = await transaction.get(canteenDoc);

        if (canteenSnapshot.exists) {
          int currentCounter = canteenSnapshot['counter'] ?? 0;
          currentCounter++;
          transaction.update(canteenDoc, {'counter': currentCounter});
          print('$canteenName counter incremented to $currentCounter');
        } else {
          transaction.set(canteenDoc, {'counter': 1});
          print('$canteenName counter initialized to 1');
        }
      });
    } catch (e) {
      print('Error incrementing counter for $canteenName: ${e.toString()}');
    }
  }
// new stuff
//counter function
//decrease counter
// Function to decrement counter.
  // Future<void> decrementCounter() async {
  //   try {
  //     // Reference to the Firestore collection and document where 'counter' is stored.
  //     CollectionReference counterCollection =
  //         FirebaseFirestore.instance.collection('counter');
  //     DocumentReference counterDoc =
  //         counterCollection.doc('RbWOWZ3qxbg4xqTIxECv');

  //     // Use a transaction to decrement the counter safely.
  //     await FirebaseFirestore.instance.runTransaction((transaction) async {
  //       DocumentSnapshot counterSnapshot = await transaction.get(counterDoc);

  //       if (counterSnapshot.exists) {
  //         int currentCounter = counterSnapshot['counter'] ?? 0;
  //         currentCounter--;
  //         transaction.update(counterDoc, {'counter': currentCounter});
  //         print('Counter decremented to $currentCounter');
  //       } else {
  //         // This shouldn't happen if you're always incrementing first.
  //         print('Counter does not exist.');
  //       }
  //     });
  //   } catch (e) {
  //     print('Error decrementing counter: ${e.toString()}');
  //   }
  // }
//decrease counter
// [New] Function to decrement counter for specific canteen
  Future<void> decrementCounterForCanteen(String canteenName) async {
    try {
      // Reference to the Firestore 'canteens' collection.
      CollectionReference canteensCollection =
          FirebaseFirestore.instance.collection('canteens');
      DocumentReference canteenDoc = canteensCollection.doc(canteenName);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot canteenSnapshot = await transaction.get(canteenDoc);

        if (canteenSnapshot.exists) {
          int currentCounter = canteenSnapshot['counter'] ?? 0;
          currentCounter--;
          transaction.update(canteenDoc, {'counter': currentCounter});
          print('$canteenName counter decremented to $currentCounter');
        } else {
          print('Error: $canteenName does not exist.');
        }
      });
    } catch (e) {
      print('Error decrementing counter for $canteenName: ${e.toString()}');
    }
  }
// new stuff

//geo fencing check new
  Future<void> geofenceCheck() async {
    try {
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      bool isInAnyGeofenceNow =
          false; // [Added] Flag to check if the user is inside any geofence during the current check.
      bool wasInGeofence = false; ////same abovr
      String? detectedCanteen; // Define a variable outside the loop
      // Iterate over all pins
      for (String pin in locationData.keys) {
        for (List<double> coords in locationData[pin]!) {
          double latitude = coords[0];
          double longitude = coords[1];
          double altitude = coords[2];

          double distanceInMeters = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            latitude,
            longitude,
          );

          if (distanceInMeters <= 10 && userPosition.altitude == altitude) {
            detectedCanteen = pin; // Update the variable when a match is found
            isInAnyGeofenceNow =
                true; // [Added] Set flag to true because user is inside a geofence.
            await incrementCounterForCanteen(pin);

            ///increment !!!!!!!!!!!
            print('User is within the geofence of $pin. Counter incremented.');
            return; // Exit the function once we find a match
          }
        }
      }
      if (wasInGeofence && !isInAnyGeofenceNow && detectedCanteen != null) {
        print('User has exited the geofence. Decrementing counter.');
        await decrementCounterForCanteen(
            detectedCanteen); // Use the variable outside the loop new stuff
      }
      wasInGeofence =
          isInAnyGeofenceNow; // Save the current geofence state for the next check.

      print('User is not within the geofence of any provided location.');
    } catch (e) {
      print('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location services"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 46.0,
              color: Colors.blue,
            ),
            const SizedBox(
              height: 20.0,
            ),
            const Text(
              "Get user Location",
              style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text("Position: $locationMessage"),
            TextButton(
              onPressed: () {
                getCurrentLocation();
                //add things here
              },
              style: TextButton.styleFrom(backgroundColor: Colors.blue[800]),
              child: const Text("Get Current Location",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
