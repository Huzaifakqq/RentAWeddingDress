import 'package:flutter/material.dart';
import 'package:rent_a_wedding_dress/models/user_session.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'rider_home_screen.dart';

class LoginScreen extends StatefulWidget {
  // ✅ Which mode to preselect (signup passes its selected role back)
  final String initialRole;

  const LoginScreen({super.key, this.initialRole = "customer"});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = "";

  // ✅ Role mode selected on the login screen
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole;
  }

  void loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final result = await AuthService.login(
      contactController.text.trim(),
      passwordController.text.trim(),
      role: selectedRole,
    );

    setState(() {
      isLoading = false;
    });

    if (result != null && result["Error"] == null) {
      UserSession.userId = result["UserId"];
      UserSession.name = result["Name"];
      UserSession.contact = result["Contact"];
      UserSession.role = result["Role"] ?? selectedRole;

      // ✅ Riders get their own app stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserSession.role == "rider"
              ? const RiderHomeScreen()
              : const HomeScreen(),
        ),
      );
    } else {
      setState(() {
        errorMessage = result?["Error"] ?? "Invalid Contact or Password";
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

              Text(
                selectedRole == "rider"
                    ? "Sign in to start delivering."
                    : "Sign in to find your perfect dress.",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),

              const SizedBox(height: 30),

              // ✅ ROLE MODE — Customer or Rider
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: buildModeButton("Customer", Icons.person),
                    ),
                    Expanded(
                      child: buildModeButton(
                        "Rider",
                        Icons.delivery_dining,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

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
                      builder: (context) =>
                          SignupScreen(initialRole: selectedRole),
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

  // ✅ Segmented mode button (Customer / Rider)
  Widget buildModeButton(String role, IconData icon) {
    final selected = selectedRole == role.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role.toLowerCase();
          errorMessage = "";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              role,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black54,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
