import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class InformationModal extends StatefulWidget {
  const InformationModal({
    Key? key,
    required this.information,
    required this.title,
  }) : super(key: key);

  final String information;
  final String title;

  @override
  _InformationModalState createState() => _InformationModalState();
}

class _InformationModalState extends State<InformationModal> {
  final ScrollController _scrollController = ScrollController();
  late bool _showFloatingButton;

  @override
  void initState() {
    super.initState();
    _showFloatingButton = false;
    _scrollController.addListener(_calculateFloatingButtonVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateShowFloatingButton();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_calculateFloatingButtonVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateFloatingButtonVisibility() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final pixels = _scrollController.position.pixels;
    final atBottom = pixels >= maxScroll;

    setState(() {
      _showFloatingButton = !_showFloatingButton || !atBottom;
    });
  }

  void _updateShowFloatingButton() {
    setState(() {
      final hasExtentAfter = _scrollController.position.extentAfter > 0;
      _showFloatingButton = hasExtentAfter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // This removes the back button
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                      data: utf8.decode(widget.information.runes.toList(),
                          allowMalformed: true)),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showFloatingButton ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
