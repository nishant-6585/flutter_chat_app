import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;

  DatabaseService({this.uid});

  //reference for our collections
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");


  final CollectionReference oneToOneMessageCollection =
  FirebaseFirestore.instance.collection("oneToOneMessages");

  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection("groups");

  //saving the user data
  Future savingUserData(String fullName, String email) async {
    return await userCollection.doc(uid).set({
      "fullName": fullName,
      "email": email,
      "oneToOne": [],
      "groups": [],
      "adminOfGroups":[],
      "profilePic": "",
      "uid": uid,
    });
  }

  //getting user data
  Future gettingUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    return snapshot;
  }

  //getting user group info
  Future getUserGroupListInfo() async {
    DocumentReference documentReference = userCollection.doc(uid);
    DocumentSnapshot documentSnapshot = await documentReference.get();
    return documentSnapshot;
  }

  // get user groups
  getUserGroups() async {
    return userCollection.doc(uid).snapshots();
  }

  getOneToOneChatList() async{
    return userCollection.doc(uid).snapshots();
  }

  Future addOneToOneChat(String userId, String userName, String currentUserName) async {
    DocumentReference currentUserDocumentReference = userCollection.doc(uid);

    await currentUserDocumentReference.update({
      "oneToOne":
      FieldValue.arrayUnion(["${userId}_$userName"])
    });

    DocumentReference userDocumentReference = userCollection.doc(userId);
    await userDocumentReference.update({
      "oneToOne":
      FieldValue.arrayUnion(["${uid}_$currentUserName"])
    });

    String groupChatId = "";
    if (uid!.compareTo(userId) > 0) {
      groupChatId = '$uid-$userId';
    } else {
      groupChatId = '$userId-$uid';
    }

    return await oneToOneMessageCollection.doc(groupChatId).set({
      "members": [uid,userId],
      "recentMessage": "",
      "recentMessageSender": "",
      "profilePic": "",
      "groupChatId": groupChatId,
    });
  }

  // creating a group
  Future createGroup(String userName, String id, String groupName) async {
    DocumentReference groupDocumentReference = await groupCollection.add({
      "groupName": groupName,
      "groupIcon": "",
      "admin": "${id}_$userName",
      "members": [],
      "groupId": "",
      "recentMessage": "",
      "recentMessageSender": "",
    });
    // update the members
    await groupDocumentReference.update({
      "members": FieldValue.arrayUnion(["${uid}_$userName"]),
      "groupId": groupDocumentReference.id,
    });

    DocumentReference userDocumentReference = userCollection.doc(uid);
    return await userDocumentReference.update({
      "groups":
      FieldValue.arrayUnion(["${groupDocumentReference.id}_$groupName"]),
      "adminOfGroups":
      FieldValue.arrayUnion(["${id}_$userName"])
    });
  }

  // getting the chats
  getGroupChatMessages(String groupId) async {
    return groupCollection
        .doc(groupId)
        .collection("groupMessages")
        .orderBy("time")
        .snapshots();
  }

  // getting the chats
  getChatMessages(String userId,) async {

    String groupChatId = "";
    if (uid!.compareTo(userId) > 0) {
      groupChatId = '$uid-$userId';
    } else {
      groupChatId = '$userId-$uid';
    }

    return oneToOneMessageCollection
        .doc(groupChatId)
        .collection("chatMessages")
        .orderBy("time")
        .snapshots();
  }

  Future getGroupAdmin(String groupId) async {
    DocumentReference d = groupCollection.doc(groupId);
    DocumentSnapshot documentSnapshot = await d.get();
    return documentSnapshot['admin'];
  }

  // get group members
  getGroupMembers(groupId) async {
    return groupCollection.doc(groupId).snapshots();
  }

  // search group by name
  searchGroupByName(String groupName) {
    return groupCollection.where("groupName", isEqualTo: groupName).get();
  }

  // search user by name
  searchUserByName(String userName) {
    return userCollection.where("fullName", isEqualTo: userName).get();
  }

  // function -> bool
  Future<bool> isUserJoined(
      String groupName, String groupId, String userName) async {
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentSnapshot documentSnapshot = await userDocumentReference.get();

    List<dynamic> groups = await documentSnapshot['groups'];
    if (groups.contains("${groupId}_$groupName")) {
      return true;
    } else {
      return false;
    }
  }

  // toggling the group join/exit
  Future toggleGroupJoin(
      String groupId, String userName, String groupName) async {
    // doc reference
    DocumentReference userDocumentReference = userCollection.doc(uid);
    DocumentReference groupDocumentReference = groupCollection.doc(groupId);

    DocumentSnapshot documentSnapshot = await userDocumentReference.get();
    List<dynamic> groups = await documentSnapshot['groups'];

    // if user has our groups -> then remove then or also in other part re join
    if (groups.contains("${groupId}_$groupName")) {
      await userDocumentReference.update({
        "groups": FieldValue.arrayRemove(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayRemove(["${uid}_$userName"])
      });
    } else {
      await userDocumentReference.update({
        "groups": FieldValue.arrayUnion(["${groupId}_$groupName"])
      });
      await groupDocumentReference.update({
        "members": FieldValue.arrayUnion(["${uid}_$userName"])
      });
    }
  }

  // send message
  sendMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    groupCollection.doc(groupId).collection("groupMessages").add(chatMessageData);
    groupCollection.doc(groupId).update({
      "recentMessage": chatMessageData['message'],
      "recentMessageSender": chatMessageData['sender'],
      "recentMessageTime": chatMessageData['time'].toString(),
    });
  }

  void sendOneToOneMessage(String userId, Map<String, dynamic> chatMessageMap) {
    String groupChatId = "";
    if (uid!.compareTo(userId) > 0) {
      groupChatId = '$uid-$userId';
    } else {
      groupChatId = '$userId-$uid';
    }

    oneToOneMessageCollection.doc(groupChatId).collection("chatMessages").add(chatMessageMap);
    oneToOneMessageCollection.doc(groupChatId).update({
      "recentMessage": chatMessageMap['message'],
      "recentMessageSender": chatMessageMap['sender'],
      "recentMessageTime": chatMessageMap['time'].toString(),
    });

  }

}
