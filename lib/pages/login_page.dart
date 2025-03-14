import "package:flutter/material.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        elevation: 0,
      ),
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          
            SizedBox(height: 25),

            // Hello Again

            Text(
              'Hello Again!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              )
              ),
          
            SizedBox(height: 5),

            Text(
              'You\'ve been missed!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black,
              )
              ),


            SizedBox(height: 50),
          
            // Email text field

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Email',
                      border: InputBorder.none,
                      ),
                    ),
                ),
              ),
            ),

            SizedBox(height: 10),
                      
            // Password text field

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: InputBorder.none,
                      ),
                    ),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Sign in button

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 20),


            // Not a member yet? Sign up

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
                'Not a member?',
                style: TextStyle(
                fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' Register now',
                style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                ),
              ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }
}
