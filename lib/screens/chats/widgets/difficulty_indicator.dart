import 'package:flutter/material.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';

class DifficultyIndicator extends StatelessWidget {
  final int difficulty;

  const DifficultyIndicator({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    //List<Widget> iconList = [];

    /*for (int i = 0; i < 3; i++) {
      if (i < difficulty) {
        iconList.add(Icon(Icons.circle, color: _getIconColor()));
      } else {
        iconList.add(Icon(Icons.circle_outlined, color: _getIconColor()));
      }
    }*/

    return Row(children: <Widget>[
      Icon(Icons.circle, color: _getIconColor(), size: 15),
      const SizedBox(width: kDefaultPadding * 0.25),
      Text(_getText()),
    ]);
  }

  Color _getIconColor() {
    if (difficulty == 3) {
      return Colors.red;
      //} else if (difficulty == 4) {
      //  return Colors.orange;
    } else if (difficulty == 2) {
      return Colors.amber;
      //} else if (difficulty == 2) {
      //  return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  String _getText() {
    if (difficulty == 3) {
      return "Diffcult";
    } else if (difficulty == 2) {
      return "Medium";
    } else {
      return "Easy";
    }
  }
}
