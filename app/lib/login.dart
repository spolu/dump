import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:developer';

final FirebaseAuth _auth = FirebaseAuth.instance;

class Login extends StatefulWidget {
  Login() : super();

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No user found for that email.'),
          ),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wrong password provided for that user.'),
          ),
        );
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    try {
      // ignore: unused_local_variable
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The passsword provided is too weak.'),
          ),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An account already exists for that email.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: [
      Expanded(child: Container()),
      SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    autofocus: true,
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'email@example.com',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 25.0),
                    ),
                    style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                    validator: (String? value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter your email.';
                      return null;
                    },
                  ),
                  TextFormField(
                    autofocus: false,
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Password',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 25.0),
                    ),
                    style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                    validator: (String? value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a password.';
                      return null;
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: Container()),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        alignment: Alignment.center,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await _signInWithEmail();
                          },
                          child: Text('Sign-up'),
                        ),
                      ),
                      SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        alignment: Alignment.center,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            await _signUpWithEmail();
                          },
                          child: Text('Sign-in'),
                        ),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      Expanded(child: Container()),
    ]));
  }
}
