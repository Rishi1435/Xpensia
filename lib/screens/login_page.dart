import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';

class Login extends StatelessWidget {
  const Login({super.key});
  Duration get loading => const Duration(milliseconds: 1000);
  Future<String?> _authUser(LoginData data) {
    return Future.delayed(loading).then((value) => null);
  }

  Future<String?> _recoverPassword(String data) {
    return Future.delayed(loading).then((value) => null);
  }

  Future<String?> _signup(SignupData data) {
    return Future.delayed(loading).then((value) => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterLogin(
        theme: LoginTheme(
          buttonTheme: LoginButtonTheme(backgroundColor: Theme.of(context).colorScheme.tertiary,),
          cardTheme: CardTheme(
            color: Theme.of(context).colorScheme.tertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(20),
            ),
          ),
          buttonStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary)
        ),
        autofocus: true,
        onLogin: _authUser,
        onRecoverPassword: _recoverPassword,
        onSignup: _signup,
        loginAfterSignUp: true,
        validateUserImmediately: true,
      ),
    );
  }
}
