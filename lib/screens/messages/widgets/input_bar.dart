import 'package:flutter/material.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';

class InputBar extends StatefulWidget {
  final Function(String) onBtnSendPressed;
  final Function() onBtnVideoPressed;
  final Function() onBtnAudioPressed;

  const InputBar({
    super.key,
    required this.onBtnSendPressed,
    required this.onBtnVideoPressed,
    required this.onBtnAudioPressed,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _chatController = TextEditingController();
  bool _isSendButtonActive = false;

  @override
  void initState() {
    super.initState();
    _chatController.addListener(_toggleSendButton);
  }

  void _toggleSendButton() {
    setState(() {
      _isSendButtonActive = _chatController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200], // Light grey background for the InputBar
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.mic_outlined,
              color: kPrimaryColor,
            ),
            onPressed: widget.onBtnAudioPressed,
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam,
              color: kPrimaryColor,
            ),
            onPressed: widget.onBtnVideoPressed,
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.white, // White background for the input field
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _chatController,
                decoration: const InputDecoration(
                  hintText: "Type message",
                  border: InputBorder.none,
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isSendButtonActive
                  ? kPrimaryColor
                  : Colors.grey, // Toggle button color
            ),
            onPressed: _isSendButtonActive
                ? () {
                    widget.onBtnSendPressed(_chatController.text);
                    _chatController.clear();
                  }
                : null, // Disable the button when there's no text
          ),
        ],
      ),
    );
  }
}
