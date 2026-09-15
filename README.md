# Rent a Wedding Dress

A full-stack wedding dress rental marketplace built with Flutter, ASP.NET Web API, and SQL Server.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: ASP.NET Web API 2 (.NET Framework 4.7.2)
- **Database**: SQL Server (Entity Framework Database-First)

## Project Structure

```
RentAWeddingDress/
├── backend/          # ASP.NET Web API project
├── frontend/         # Flutter mobile app
├── database/         # SQL Server database backup (.bacpac)
└── README.md
```

## Features

- User registration and login
- Browse and search wedding dresses
- Advanced filtering (category, occasion, price, size, condition)
- Dress upload with multiple images
- Booking system with availability checking
- Booking status workflow (Pending → Accepted → Picked → Confirmed → Return → Completed)
- Rating and review system
- Customer and Owner dashboards

## Setup Instructions

### Database

1. Open SQL Server Management Studio (SSMS)
2. Right-click **Databases** → **Import Data-tier Application**
3. Select `database/RentAWeddingDress.bacpac`
4. Follow the wizard to complete import

### Backend (API)

1. Open `backend/RentAWeddingDressAPI.slnx` in Visual Studio
2. Restore NuGet packages
3. Update connection string in `Web.config` if needed
4. Build and run (Ctrl+F5)
5. Note the port number (e.g., `http://localhost:54321`)

### Frontend (Flutter)

1. Open `frontend/` in Android Studio or VS Code
2. Update `lib/config.dart` with your API IP address:
   ```dart
   static const String baseUrl = "http://YOUR_IP:PORT/api";
   static const String imageBaseUrl = "http://YOUR_IP:PORT/";
   ```
3. Run `flutter pub get`
4. Run the app on emulator or device

## API Endpoints

| Route | Method | Purpose |
|-------|--------|---------|
| `api/auth/register` | POST | Register new user |
| `api/auth/login` | POST | Login |
| `api/dresses/filter` | POST | Search/filter dresses |
| `api/dresses/{id}` | GET | Get dress details |
| `api/dresses/upload-image` | POST | Upload image |
| `api/dresses/create` | POST | Create new dress |
| `api/dresses/categories` | GET | Get categories |
| `api/dresses/sizes` | GET | Get sizes |
| `api/bookings/check` | POST | Check availability |
| `api/bookings/confirm` | POST | Confirm booking |
| `api/rentals/user/{id}` | GET | Customer bookings |
| `api/rentals/owner/{id}` | GET | Owner bookings |
| `api/rentals/update-status` | POST | Update booking status |
| `api/rentals/add-review` | POST | Submit review |
| `api/users/add-address` | POST | Add address |
| `api/users/{id}/addresses` | GET | Get addresses |

## Booking Status Flow

```
0 (Pending) → 1 (Accepted) → 4 (Picked) → 5 (Pickup Confirmed) → 6 (Return Requested) → 7 (Completed)
0 (Pending) → 2 (Rejected)
0 (Pending) → 3 (Cancelled)
```

## License

This project was developed as a Final Year Project (FYP).
