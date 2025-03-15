import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:tacoprime/pages/forgot_password_page.dart";

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

// Text Controllers

final _emailController = TextEditingController();
final _passwordController = TextEditingController();

Future signIn() async {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: _emailController.text.trim(), 
    password: _passwordController.text.trim()
    );
}

@override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
          child: SingleChildScrollView(
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
                      controller: _emailController,
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
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                        ),
                      ),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Forgot password

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder:(context) {
                              return ForgotPasswordPage();
                            },
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
              SizedBox(height: 30),
            
              // Sign in button
            
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: signIn,
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
                GestureDetector(
                  onTap: widget.showRegisterPage,
                  child: Text(
                    ' Register now',
                    style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
