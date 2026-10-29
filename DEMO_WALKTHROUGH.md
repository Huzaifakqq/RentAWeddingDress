# DEMO WALKTHROUGH SCRIPT
## Rent a Wedding Dress — FYP Demo

---

## PRE-DEMO CHECKLIST (do this 30 min before)

| # | Task | Command/Action | ✓ |
|---|------|---------------|---|
| 1 | SQL Server running | Services → SQL Server (SQLEXPRESS) | ☐ |
| 2 | IIS running + API up | Open `http://127.0.0.1/RentAWeddingDressAPI/api/dresses/categories` in browser | ☐ |
| 3 | Phone + PC on SAME WiFi | Both connected to same network | ☐ |
| 4 | Find PC IP | `ipconfig` → note IPv4 (currently `192.168.0.103`) | ☐ |
| 5 | Update config.dart if IP changed | Edit `frontend/lib/config.dart` → set your PC IP | ☐ |
| 6 | Install APK | Copy `frontend/build/app/outputs/flutter-apk/app-debug.apk` to phone → install | ☐ |
| 7 | App opens + login screen shows | Launch app on phone | ☐ |

### If anything breaks:
- **API not loading:** IIS → Sites → Default Web Site → check `RentAWeddingDressAPI` app exists, recycle it
- **DB error:** `sqlcmd -S localhost\SQLEXPRESS -U sa -P 123 -C -Q "USE RentAWeddingDress; SELECT COUNT(*) FROM Users;"`
- **Phone can't connect:** Firewall → allow inbound TCP 80; confirm same WiFi; try phone browser → `http://192.168.0.103/RentAWeddingDressAPI/api/dresses/categories`
- **Rebuild DB from scratch:** Run `database/CreateDatabase.sql` then `database/DemoSeed.sql` in SSMS

---

## DEMO ACCOUNTS (already seeded)

| Role | Contact | Password | Has |
|------|---------|----------|-----|
| **Owner (Admin)** | `03001234567` | `123` | 4 dresses, shop location set, multiple bookings |
| Customer (Ali) | `03001111111` | `123` | 1 accepted booking |
| Customer (Sara) | `03002222222` | `123` | 1 completed booking (has review) |
| Customer (Usman) | `03003333333` | `123` | 1 picked booking |
| Customer (Fatima) | `03004444444` | `123` | 1 pending booking |

**Tip:** Use two phones if possible — one as Owner, one as Customer. If only one phone, logout/login between roles.

---

## SCRIPT A: CUSTOMER FLOW (~8 min)

### A1. Login as Customer (2 min)
1. Open app → **Login** screen
2. Contact: `03001111111`, Password: `123`
3. → **Home screen** shows "Welcome" + Set Shop Location button
4. Tap **Dresses** tab → catalog loads with 6 dresses

> **Say:** *"Users register with phone number and password. The home screen has a one-tap shop location setter for owners."*

### A2. Browse & Search (1 min)
1. On Dresses screen, type "bridal" in search → filter results
2. Clear search → all dresses back

### A3. Advanced Filters (2 min)
1. Tap **Filter** button → bottom sheet opens
2. Select **Category: Bridal** → Apply
3. → Only bridal dresses shown
4. Open Filter again → set **Price Max: 5000** → Apply
5. → Only Green Mehndi Lehenga (Rs. 4500) remains
6. Tap **Reset** in filter → all dresses back

> **Say:** *"Advanced filters include category, subcategory, occasion, sizes, price range, condition, age, and a Near Me toggle that uses GPS."*

### A4. Dress Details (1 min)
1. Tap **Beautiful Red Bridal**
2. Show: image, description (expand), sizes M/L with stock 3 each, rating section
3. Mention: **Book** button at bottom

### A5. Book a Dress (3 min)
1. Tap **Book**
2. **Dates:** pick a range 2–3 weeks out (avoid the greyed/blocked dates)
3. **Size:** increase M quantity to 2
4. **Address:** tap an address OR tap "Add Address" → maps opens → tap to drop pin → confirm
5. Tap **Check Availability** → "Available!"
6. Tap **Confirm Booking** → success message

> **Say:** *"The booking calendar greys out dates already booked by others. Availability is checked server-side across all sizes. Delivery location is pinned on Google Maps and saved to the user's address."*

---

## SCRIPT B: OWNER FLOW (~8 min)

### B1. Login as Owner (1 min)
1. Logout (top-right on Home)
2. Login: `03001234567` / `123`

### B2. Set Shop Location (1 min)
1. On Home, tap **Set Shop Location**
2. → "Shop location updated for 4 dress(es)"
3. These dresses now appear in customer's **Near Me** filter

> **Say:** *"One tap sets the shop GPS location for ALL of the owner's dresses. New uploads auto-inherit this location."*

### B3. Upload a New Dress (2 min)
1. Tap **Upload Dress** tab
2. Pick an image from gallery
3. Fill: Title "Demo Pearl Bridal", Category Bridal, Subcategory Nikah Dress
4. Occasion: tap "Nikkah"
5. Condition: 8, Age: 0y 6m
6. Sizes: check M (stock 2), L (stock 1)
7. Price: 5500, Description: anything
8. Tap **Upload** → success

> **Say:** *"Owners upload with multiple images, multi-size stock, occasion tags. The dress auto-inherits the shop location set earlier."*

### B4. Manage Bookings (3 min)
1. Tap **My Rentals** tab → shows two sections: customer bookings + owner bookings
2. Under **Owner Bookings**, find a **Pending** booking → tap **Accept**
3. Show status badge changes: Pending → Accepted
4. Walk through status flow buttons: Accept → Picked → Confirmed → Return → Complete
5. Show a **Completed** booking has a **Review** button

> **Say:** *"The owner manages the full lifecycle: accept, mark picked, confirm pickup, request return, mark complete. Statuses are enforced server-side — you can't skip steps."*

---

## SCRIPT C: RESCHEDULE + CALENDAR BLOCKING (2 min)

### C1. Reschedule a Booking
1. Login as Customer (Ali: `03001111111` / `123`)
2. **My Rentals** → find Accepted booking → tap **Reschedule**
3. Calendar opens → show **greyed/red booked days** (dates already taken by other bookings)
4. Try to select a range that includes a blocked day → error: *"Range includes booked dates"*
5. Pick a valid range → **Select** → confirm

> **Say:** *"The reschedule calendar blocks dates already booked for that dress, preventing double-booking. The server re-checks stock before confirming."*

---

## SCRIPT D: REVIEW (1 min)

1. Login as Sara: `03002222222` / `123`
2. **My Rentals** → find Completed booking → tap **Review**
3. Give 5 stars + comment → submit

---

## TALKING POINTS (if asked)

| Topic | Answer |
|-------|--------|
| **Tech stack** | Flutter (frontend), ASP.NET Web API 2 (backend), SQL Server + EF6 Database-First (EDMX) |
| **Multi-size booking** | One order can contain multiple sizes with individual quantities (e.g. 2×M + 1×L) |
| **Availability logic** | `DressSizes.Stock` − active bookings (cancelled/rejected excluded) |
| **Status flow** | 0 Pending → 1 Accepted → 4 Picked → 5 Pickup Confirmed → 6 Return Requested → 7 Completed; 2 Cancelled, 3 Rejected |
| **Near Me** | GPS lat/lng bounding-box filter on dress shop location |
| **Penalty** | Currently waived (Rs. 0) — architecture supports percentage-based penalty |
| **Security (known)** | Plaintext passwords, no JWT — would add in production |
| **Google Maps** | Address picker for delivery, shop location for owner, Near Me filter |

---

## QUICK RECOVERY

| Problem | Fix |
|---------|-----|
| App shows login but API fails | Check phone browser: `http://[YOUR_IP]/RentAWeddingDressAPI/api/dresses/categories` |
| Blank dress images | Expected — seed uses placeholder path; upload a real dress to show images working |
| "Object reference" error | IIS app pool recycle: IIS Manager → App Pools → recycle |
| Phone can't reach PC | Same WiFi? Firewall port 80 open? Correct IP in config.dart? |
| Need clean DB | Drop DB → run `CreateDatabase.sql` → run `DemoSeed.sql` |

---

## FILES FOR DEMO

| File | Location |
|------|----------|
| APK to install | `frontend/build/app/outputs/flutter-apk/app-debug.apk` |
| DB recreate script | `database/CreateDatabase.sql` |
| Demo seed script | `database/DemoSeed.sql` |
| This script | `DEMO_WALKTHROUGH.md` |
