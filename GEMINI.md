# SkidKZ - Mobile Prototype

## Project Overview
SkidKZ is a marketplace platform where users can buy goods and services at discounted prices using referral codes from Wanghongs (influencers). This project is a high-fidelity clickable prototype built with Flutter.

## Tech Stack
- **Framework:** Flutter (Mobile)
- **State Management:** Riverpod (NotifierProvider)
- **Navigation:** GoRouter (ShellRoutes for nested navigation)
- **Theming:** Custom `AppTheme` (Google Fonts Inter, Light Blue/Gray palette)
- **Mock Data:** In-memory `MockDatabase` with predefined users, products, and orders.

## Architecture
The app follows a Feature-First architecture:
- `lib/core`: Theme, Router.
- `lib/data`: Models, Mock Repositories.
- `lib/features`: Auth, Buyer, Seller, Wanghong, Admin (each with screens).

## User Flows Implemented
1.  **Auth:** Role selection demo screen -> Mock Login.
2.  **Buyer:** Catalog -> Product Details (Unlock Price with 'IVAN25') -> Payment Sim -> Orders.
3.  **Seller:** My Products (Add Product) -> Incoming Orders (Fulfill).
4.  **Wanghong:** Dashboard (Earnings, Balance, Promo Code) -> Payout Request.
5.  **Admin:** Moderation Queue (Approve/Reject Products) -> User List.

## Key Features
- **Dynamic Pricing:** Logic to switch from Retail to SkidKZ price upon valid promo code.
- **Role-Based Routing:** Auto-redirect based on selected role.
- **State Persistence:** Adding a product as Seller makes it visible to Buyer immediately (in-session).
- **Earnings Calculation:** Wanghong earnings auto-update based on mock orders.

## Changelog
- Initial prototype creation.
- Implemented all 4 user roles.
- Added mock payment and moderation flows.
