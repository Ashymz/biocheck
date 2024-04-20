import 'package:biocheck/utils/media.dart';
import 'package:flutter/material.dart';


class Custombutton {
  static Widget button(clr, text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(15),
            ),
            color: clr,
          ),
          height: height / 17.5,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                  color: clr != Colors.white ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold ),
            ),
          ),
        ),
      ),
    );
  }
}
