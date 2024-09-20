import 'package:flutter/material.dart';
import 'package:jumping_dot/jumping_dot.dart';

import 'package:comm_skills_chatbot_kestrel/constants.dart';

import 'package:comm_skills_chatbot_kestrel/models/local_message.dart';

class LoadingMessage extends StatelessWidget {
  const LoadingMessage({
    super.key,
    this.message,
  });

  final LocalMessage? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: MediaQuery.of(context).platformBrightness == Brightness.dark
      //     ? Colors.white
      //     : Colors.black,
      width: 70,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 0.75,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: kPrimaryColor
            .withOpacity(message!.role == LocalMessageRole.user ? 1 : 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: JumpingDots(
        numberOfDots: 3,
        color: Colors.grey,
        radius: 3,
        innerPadding: 4.5,
        delay: 1000,
        //verticalOffset: -1,
        //animationDuration = Duration(milliseconds: 200),
      ),
    );
  }
}
