import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/auth_providers.dart';

class CrewChatScreen extends ConsumerStatefulWidget {
  const CrewChatScreen({super.key});

  @override
  ConsumerState<CrewChatScreen> createState() => _CrewChatScreenState();
}

class _CrewChatScreenState extends ConsumerState<CrewChatScreen> {
  final _msgController = TextEditingController();
  String? _boatId;

  @override
  void initState() {
    super.initState();
    _resolveBoat();
  }

  Future<void> _resolveBoat() async {
    final member = ref.read(currentUserProvider).value;
    if (member?.sailNumber != null) {
      setState(() => _boatId = member!.sailNumber);
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _boatId == null) return;

    final member = ref.read(currentUserProvider).value;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await FirebaseFirestore.instance
        .collection('crew_chats')
        .doc(_boatId)
        .collection('messages')
        .add({
      'text': text,
      'authorUid': uid,
      'authorName': member?.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });

    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_boatId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crew Chat')),
        body: const Center(
          child: Text('No boat assigned — chat requires a sail number'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Crew Chat — $_boatId')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('crew_chats')
                  .doc(_boatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final text = d['text'] as String? ?? '';
                    final author = d['authorName'] as String? ?? '';
                    final ts = d['timestamp'] as Timestamp?;
                    final isMe = d['authorUid'] ==
                        FirebaseAuth.instance.currentUser?.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(author,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800)),
                            Text(text),
                            if (ts != null)
                              Text(
                                DateFormat.jm().format(ts.toDate()),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Message your crew...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
