# SkidKZ Project Documentation

## Tech Stack
- **Framework:** Flutter (latest)
- **State Management:** Riverpod
- **Navigation:** go_router (ShellRoute for nested navigation)
- **UI:** Material 3 with "Minimal Business" aesthetic (Russian)
- **Localization:** Hardcoded Russian strings (as requested for prototype)

## Architecture
- **Features:** Organized by domain (Auth, Buyer, Seller, Wanghong, Admin).
- **Core:** Shared widgets (`RoleShell`, `ProfileScreen`) and Theme.
- **Data:** `MockDatabase` singleton provider for simulating backend, auth, and orders.

## Key Features
1.  **Role-Based Access:** Instant switching between Buyer, Seller, Wanghong, Admin.
2.  **Mock Economy:**
    - Retail Price vs SkidKZ Price (unlocked via promo code).
    - Wholesale Price for Sellers (margin calculation).
    - Wanghong Commission (10%).
3.  **Android Back Handling:**
    - `PopScope` used in `RoleShell`.
    - Logic: Back -> Main Tab -> SnackBar -> Exit.
4.  **No Images:** All visuals use Emojis/Icons.

## Changelog
- **Refined Prototype:**
    - Translated all UI to Russian.
    - Implemented specific Back Button logic.
    - Added "Add Product" flow for Sellers.
    - Added "Deals" and "Wallet" for Wanghons.
    - Added "Moderation" and "User Management" for Admins.
    - Implemented Promo Code logic (`IVAN25`).
