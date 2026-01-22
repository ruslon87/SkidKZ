# SkidKZ Flutter Project

## Overview
SkidKZ is a mobile application prototype connecting Buyers, Sellers, and Wanghongs (Recommendations).
Built with Flutter, Riverpod, and GoRouter.

## Tech Stack
- **Framework:** Flutter (Material 3)
- **State Management:** flutter_riverpod
- **Navigation:** go_router
- **Localization:** Russian (Hardcoded for Prototype)
- **Data:** Mock In-Memory Database

## Key Features
- **Role Selection:** Buyer, Wanghong, Seller, Admin.
- **Buyer:** Catalog, Product Details (Promo Code Logic), Orders.
- **Wanghong:** Dashboard, Earnings Tracking, Payout Request.
- **Seller:** Product Management (Add/Edit), Order Fulfillment.
- **Admin:** Moderation Queue, Deal Management.

## Architecture
- `lib/core`: Routing, Theme, Shared Widgets.
- `lib/data`: Models, Mock Database (Repositories).
- `lib/features`: Feature-based folders (Auth, Buyer, Seller, Wanghong, Admin).

## Recent Changes
- Fixed Back Button logic for Android (PopScope in RoleShell).
- Translated entire UI to Russian.
- Implemented Mock Economy logic (Margins, Commissions).
- Fixed Flutter Analysis errors (Type safety, Provider usage).