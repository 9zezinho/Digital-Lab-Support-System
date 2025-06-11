import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service class that interacts with Firestore and Firebase Authentication to
/// perform various tasks such as fetching users, managing session data, updating
/// user roles,, and uploading & fetching feedbacks.
///
/// This class follows the singleton pattern, ensuring that only one instance of
/// the service is used throughout the application. It is primarily responsible
/// for handling Firestore database operations related to users, sessions, and
/// other application-specific data.
///
/// This class uses Firebase Firestore for real-time data synchronisation and
/// Firebase Authentication for handling user sessions.

class FirestoreService{
  //Only one instance of FirestoreService
  static final FirestoreService _instance = FirestoreService._internal();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final userId = _auth.currentUser!.uid;

  factory FirestoreService() => _instance;

  FirestoreService._internal();

  //Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Fetch users with optional role filtering
  Stream<QuerySnapshot> fetchUsers({String? role}) {
    Query usersQuery = _firestore.collection("users");

    if(role!=null) {
      usersQuery = usersQuery.where("role", isEqualTo: role);
    }
    return usersQuery.snapshots();
  }

  //Update user role
  Future<void> updateUserRole(String userId, String newRole) async{
    await _firestore.collection("users")
        .doc(userId).update({"role": newRole});
  }

  //Fetch sessionQueue
  Stream<DocumentSnapshot> fetchSessionQueue(String sessionId) {
    return _firestore
        .collection('sessions').doc(sessionId).snapshots();
  }

  //Remove a request from queue
  Future<void> removeRequest(String sessionId, String requestId,
      [String? requestType]) async {
    try{
      var sessionRef = _firestore.collection("sessions").doc(sessionId);
      var sessionDoc = await sessionRef.get();

      List<dynamic> studentQueue = sessionDoc["studentQueue"];

      var requestToRemove = studentQueue.firstWhere(
          (request) => request["requestId"] == requestId,
        orElse: () => null,
      );

      if (requestToRemove != null) {
        //Extract data before removing from Firebase
        final timeStampCreated = requestToRemove["requestedAt"];
        final actualRequestType = requestToRemove["requestType"];

        print("Trying to remove request Id: $requestToRemove" );

        //Filter out the removed request
        studentQueue.removeWhere((item) => item["requestId"] == requestId);
        await sessionRef.update({
          "studentQueue": studentQueue
        });

        await sessionRef
            .collection("requestHistory").doc(requestId).set({
          "requestId": requestId,
          "requestType": actualRequestType,
          "timeStampCreated": timeStampCreated,
          "timeStampCompleted": Timestamp.now(),
        });
      }

      //Raise feedback flag only if requestType is sign-off
      if(requestType == "sign-off") {
        String studentUid = requestToRemove["uid"];

        await sessionRef.update({
          "feedbackTriggers.$studentUid":{
            "uid":requestToRemove["uid"],
            "requestId": requestId,
            "showDialog": true,
            "timestamp": FieldValue.serverTimestamp()
          }
        });
      }

    } catch(e) {
      throw Exception("Failed to mark request: $e");
    }
  }

  //Fetch open sessions
  Stream<QuerySnapshot> fetchOpenSession(String status) {
    return _firestore.collection('sessions').where(
      'status', isEqualTo: status).snapshots();
  }

  //Join a session
  Future<String?> joinSession(String sessionCode) async {
    try{
      // Check if the session code exits in the Firestore database
      var sessionSnapshot = await _firestore
          .collection("sessions")
          .where("sessionCode", isEqualTo: sessionCode)
          .where("status", isEqualTo: "open")
          .get();

      if(sessionSnapshot.docs.isEmpty){
        return null;
      }

      String sessionId = sessionSnapshot.docs[0].id;
      // String userId = _auth.currentUser!.uid;

      DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

      String userName = userDoc.exists ? userDoc["fullName"]
          ?? "Student": "Student";

      //Add Student/User to the session in Firestore
      await _firestore.collection('sessions')
          .doc(sessionId).update({
        "users": FieldValue.arrayUnion([
          {"uid": userId, "name": userName}
        ])
      });

      return sessionId;
    } catch(e) {
      throw Exception("Failed to join Session: $e");
    }
  }

  //Close Session
  Future<void> closeSession(String sessionId) async {
    await _firestore.collection('sessions')
        .doc(sessionId).update({
      'status': 'closed',
      'users': [],
      'studentQueue': []
    });
  }

  // Fetch joined session
  Stream<List<DocumentSnapshot>> fetchJoinedSession(String status) {

    return _firestore
        .collection("sessions")
        .where("status", isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            try {
              var users = doc.data()["users"] as List<dynamic>?;
              if (users == null) return false;

              return users.any((student) =>
              student is Map<String, dynamic> && student["uid"] == userId);
            } catch(e)  {
              return false;
            }
          }).toList();
    });
  }

  //Upload assigned modules to lecturer
  Future<void> assignModules(String lecturerId,
      List<String>modules)async {
    _firestore.collection('users').doc(lecturerId).update({
      "assignedModules": modules,
    });
  }

  //Retrieve already assigned modules to lecturer
  Stream<List<String>> fetchAssignedModules(String lecturerId) {

    return  _firestore.collection("users").doc(lecturerId).snapshots().map((doc) {
      if(doc.exists && doc.data()!.containsKey('assignedModules')) {
        List<dynamic> modulesFromDb = doc['assignedModules'];
        return modulesFromDb.cast<String>();
      } else {
        return [];
      }
    });
  }

  //Retrieve the modules each closed session
  Stream<List<Map<String, String>>> fetchClosedSessionOfModule(String createdFor) {
    return _firestore.collection('sessions')
        .where("status", isEqualTo: "closed")
        .where("createdFor",isEqualTo: createdFor)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
              'sessionName': doc['sessionName'] as String,
              'sessionId': doc.id,
            }).toList());
  }

  //Listen to changes of remove of request(sign-off)
  Stream<List<dynamic>> listenToStudentQueue(String sessionId) {
    return  _firestore.collection("sessions").doc(sessionId)
        .snapshots().map((snapshot) {
          if(snapshot.exists && snapshot.data() !=null) {
            return snapshot.data()!["studentQueue"] ?? [];
          }
          return [];

    });
  }

  // Update the flag
  Future<void> makeDialogFalse(String sessionId) async{
    _firestore.collection("sessions")
        .doc(sessionId).update({
      "feedbackTriggers.$userId.showDialog":false,
    });

  }
  
  //Upload the feedbacks to Firebase
  Future<void> uploadFeedback(String sessionId, String labDifficulty,
      double assistanceRating, double waitingTimeRating, String comment)
  async {
    _firestore.collection("sessions").doc(sessionId)
        .collection("feedbacks").add({
      "labDifficulty": labDifficulty,
      "assistanceRating": assistanceRating,
      "waitingTimeRating":waitingTimeRating,
      "comment": comment
    });
  }

  //Get Feedback Summary
  Stream<List<Map<String, dynamic>>> getFeedbackSummary(String sessionId) {
    return _firestore.collection("sessions").doc(sessionId)
        .collection("feedbacks")
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  //Retrieve timeStamp for assistance and sign off
  Stream<List<Map<String, dynamic>>> getTimeStamp(String sessionId) {
    return _firestore.collection("sessions").doc(sessionId)
        .collection("requestHistory")
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }
}
