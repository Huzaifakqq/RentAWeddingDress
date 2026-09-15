import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = "";

  void registerUser() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final result = await AuthService.register(
      nameController.text.trim(),
      contactController.text.trim(),
      passwordController.text.trim(),
      confirmPasswordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created Successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      setState(() {
        errorMessage = result ?? "Registration Failed";
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
              const SizedBox(height: 100),

              Image.asset("assets/images/logo.png", height: 80),

              const SizedBox(height: 30),

              const Text(
                "Create Account",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Elegance for every moment",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 40),

              buildInputField("Full Name", nameController),
              const SizedBox(height: 20),
              buildInputField("Email or Phone Number", contactController),
              const SizedBox(height: 20),
              buildInputField("Password", passwordController, isPassword: true),
              const SizedBox(height: 20),
              buildInputField(
                "Confirm Password",
                confirmPasswordController,
                isPassword: true,
              ),

              const SizedBox(height: 15),

              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: registerUser,
                        child: const Text("Create Account"),
                      ),
                    ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: "Log In",
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

  Widget buildInputField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
