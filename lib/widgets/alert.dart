import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

alert(BuildContext context, type, String message) {
  showTopSnackBar(
    Overlay.of(context),
    type == "error"
        ? CustomSnackBar.error(
            message: message,
          )
        : CustomSnackBar.success(
            message: message,
          ),
  );
}
