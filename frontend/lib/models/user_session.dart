class UserSession {
  static int? userId;
  static String? name;
  static String? contact;

  // ✅ "customer" (default) or "rider" — set at login
  static String role = "customer";
}
