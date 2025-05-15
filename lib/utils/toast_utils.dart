import 'package:flutter/material.dart';

// Show a Flutter toast message
void showFlutterToast(
  BuildContext context, {
  required String message,
  required String errorInfo,
}) {
  Color backgroundColor = errorInfo == 'error' ? Colors.red : Colors.green;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(8),
    ),
  );
} 