import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = "";

  void loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final result = await AuthService.login(
      contactController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result != null) {
      UserSession.userId = result["UserId"];
      UserSession.name = result["Name"];
      UserSession.contact = result["Contact"];
      // ✅ Navigate to Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        errorMessage = "Invalid Contact or Password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 120),

              // ✅ Logo
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Image.asset("assets/images/logo.png"),
              ),

              const SizedBox(height: 40),

              const Text(
                "Welcome Back",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Sign in to find your perfect dress.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // ✅ Contact Field
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  hintText: "Email or Phone Number",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Password Field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 25),

              // ✅ Login Button
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: loginUser,
                        child: const Text(
                          "Log In",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
