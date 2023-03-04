import 'dart:io';

import 'package:chatmandu/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';

import '../constants/firebase_instances.dart';
import '../providers/room_provider.dart';
import '../services/post_services.dart';

class ChatPage extends ConsumerStatefulWidget {
  final types.Room room;
  const ChatPage({required this.room});




  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  bool _isAttachmentUploading = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Consumer(builder: (context, ref, child) {

        final roomMessage = ref.watch(messageStream(widget.room));

        return roomMessage.when(
            data: (data) {
              return Chat(
                showUserAvatars: true,
                showUserNames: true,
                isAttachmentUploading: _isAttachmentUploading,
                messages: data,
                onAttachmentPressed: () {
                  final ImagePicker _picker = ImagePicker();
                  _picker.pickImage(source: ImageSource.gallery).then((value)async {
                    if(value != null){
                      setState(() {
                        _isAttachmentUploading = true;
                      });
                      final ref = FirebaseInstances.fireStorage.ref().child('chatImage/${value.name}');
                      await ref.putFile(File(value.path));
                      final url = await ref.getDownloadURL();
                      setState(() {
                        _isAttachmentUploading = false;
                      });
                      final imageMessage = types.PartialImage(
                          name: value.name,
                          uri: url,
                          size:  File(value.path).lengthSync()
                      );
                      FirebaseChatCore.instance.sendMessage(
                        imageMessage,
                        widget.room.id,
                      );
                    }
                  });



                },
                onSendPressed: (types.PartialText message) {
                  FirebaseChatCore.instance.sendMessage(
                    message,
                    widget.room.id,
                  );
                },
                user: types.User(
                  id: FirebaseChatCore.instance.firebaseUser!.uid,
                ),
              );
            },
            error: (err, stack) => Center(child: Text('$err')),
            loading: () => Center(child: CircularProgressIndicator()));
      }),
    );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }
}