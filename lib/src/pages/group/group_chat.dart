import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GroupPage extends StatefulWidget {
  final String name;
  const GroupPage({super.key, required this.name});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late IO.Socket socket;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> listMsg = [];
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _canSend = _controller.text.trim().isNotEmpty));
    connect();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    try {
      socket.disconnect();
    } catch (_) {}
    super.dispose();
  }

  void connect() {
    socket = IO.io(
      "http://192.168.100.20:3000",
      <String, dynamic>{
        "transports": ["websocket"],
        "autoConnect": false,
      },
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint("✅ connected into frontend");

      socket.on("sendMsgServer", (msg) {
        debugPrint("📥 received: $msg");
        final incoming = Map<String, dynamic>.from(msg);
        incoming['time'] = incoming['time'] ?? _formatTime(DateTime.now());
        setState(() {
          listMsg.add(incoming);
        });
        _scrollToBottom();
      });
    });

    socket.onConnectError((err) {
      debugPrint("❌ Connect error: $err");
    });

    socket.onDisconnect((_) {
      debugPrint("❌ Disconnected from server");
    });
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void sendMsg(String msg) {
    if (msg.trim().isEmpty) return;

    final ownMsg = {
      "msg": msg.trim(),
      "senderName": widget.name,
      "type": "ownMsg",
      "time": _formatTime(DateTime.now())
    };

    setState(() {
      listMsg.add(ownMsg);
    });
    _scrollToBottom();

    socket.emit("sendMsg", ownMsg);
    _controller.clear();
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final mine = msg["type"] == "ownMsg";
    final sender = msg['senderName'] ?? 'Unknown';
    final time = msg['time'] ?? '';

    final radius = Radius.circular(16);
    final bubbleRadius = BorderRadius.only(
      topLeft: mine ? radius : Radius.zero,
      topRight: mine ? Radius.zero : radius,
      bottomLeft: radius,
      bottomRight: radius,
    );

    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!mine)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.primaries[sender.hashCode % Colors.primaries.length],
              child: Text(
                (sender.isNotEmpty ? sender[0].toUpperCase() : '?'),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: mine ? Colors.blueAccent : Colors.grey.shade200,
                borderRadius: bubbleRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        sender,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  Text(
                    msg['msg'] ?? '',
                    style: TextStyle(
                      color: mine ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: (mine ? Colors.white70 : Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (mine)
          const SizedBox(width: 40), // space for symmetry with avatar side
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.primaries[widget.name.hashCode % Colors.primaries.length],
              child: Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Group Chat",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: listMsg.length,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemBuilder: (context, index) {
                    final msg = listMsg[index];
                    return _buildBubble(msg);
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: sendMsg,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Type a message",
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // placeholder for attachments
                            },
                            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _canSend ? Colors.blueAccent : Colors.grey.shade400,
                    shape: const CircleBorder(),
                    child: IconButton(
                      color: Colors.white,
                      onPressed: _canSend ? () => sendMsg(_controller.text) : null,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
