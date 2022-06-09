import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();

  String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  Future<void> getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser);
      }
    } catch (e) {
      print(e);
    }
  }

  // void messagesStreams() async {
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                // Implement logout functionality
                try {
                  await _auth.signOut();
                  Navigator.pop(context);
                } catch (e) {
                  print(e);
                }

                // messagesStreams();
              }),
        ],
        title: Text('Group Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                "https://images.unsplash.com/photo-1583935115064-3785d46de1dc?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxzZWFyY2h8MXx8cGxhaW4lMjBjb2xvdXJ8ZW58MHx8MHx8&w=1000&q=80"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    },
                    child: Icon(
                      Icons.send,
                      color: Colors.lightBlueAccent,
                    ),
                    // Text(
                    //   'Send',
                    //   style: kSendButtonTextStyle,
                    // ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.text, this.sender, this.isMe, this.timestamp});
  final String text;
  final String sender;
  final bool isMe;
  final timestamp;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        '$text',
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              color: Colors.black45,
              fontSize: 8,
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomRight,
          //   child: Text(
          //     timestamp,
          //     style: TextStyle(
          //       color: Colors.black54,
          //       fontSize: 12,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  String getMessageTime(var timeStamp) {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(
        timeStamp.millisecondsSinceEpoch);
    var formatTime = new DateFormat('HH:mm');
    var timeString = formatTime.format(date);
    return timeString;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.get('text');
          final messageSender = message.get('sender');
          final messageTime = message.get('timestamp') == null
              ? getMessageTime(DateTime.now())
              : getMessageTime(message.get('timestamp'));
          final currentUser = loggedInUser;
          final messageBubble = MessageBubble(
            text: messageText,
            sender: messageSender,
            isMe: currentUser.email == messageSender,
            timestamp: messageTime,
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}
