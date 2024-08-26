import 'package:flutter/material.dart';

class FailedLogin extends StatelessWidget {
  const FailedLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/no_data.png'),
            const Text(
              "Login Failed",
              style: TextStyle(
                fontSize: 16.0
              ),
            ),
          ],
        ),
      ),
    );
  }
}
