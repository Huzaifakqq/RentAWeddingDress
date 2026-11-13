class Config {
  // Phase 1 test: local ASP.NET Core port (PostgreSQL in Docker)
  // Local-only demo value — do NOT commit (same rule as the LAN IP / tunnel URL).
  static const String baseUrl = "http://localhost:5199/api";

  static const String imageBaseUrl = "http://localhost:5199/";
}
