# SkidKZ Project Documentation

## Project Overview
SkidKZ is a Flutter-based MVP for a discount platform connecting Buyers, Sellers, and Wanghuns (recommenders). The app features a role-based system with specific pricing and revenue sharing logic.

## Tech Stack
- **Framework**: Flutter (Channel stable)
- **State Management**: Riverpod (NotifierProvider)
- **Navigation**: GoRouter
- **Localization**: Russian (hardcoded UI text)
- **Data**: Mock in-memory database with reactive providers

## Architecture
- **Feature-first** folder structure (`lib/features/role/screens`)
- **Repository Pattern** for data access (MockDatabase)
- **Domain Models**: Product, Order, User

## Key Features
1.  **Dynamic Pricing**:
    -   Retail Price (R) set by Seller.
    -   Seller Payout (W) <= 92% of R.
    -   Customer Price (C) calculated to ensure >= 3% platform margin.
    -   `skidkzPrice` displayed to buyers after promo code.

2.  **Wanghun Economy**:
    -   Earnings: 90% of platform margin.
    -   Hold Period: 14 days (implemented via `holdUntil` in Order).
    -   Wallet: Automatically segregates "Available" vs "Hold" balances.
    -   Withdrawal: Minimum 1000 KZT.

3.  **Roles**:
    -   **Buyer**: Catalog, Promo Code (`IVAN25`), Checkout, Order History.
    -   **Seller**: Add Product/Service, View Payouts.
    -   **Wanghun**: Dashboard, Wallet, Deals Analytics.
    -   **Admin**: Moderation, Transaction Monitoring.

## Changelog
- **Initial Setup**: Project creation and structure.
- **Refactoring**: Unified `Product` and `Order` models.
- **Fixes**: Fixed `flutter analyze` issues (deprecation warnings, unused variables).
- **Logic**: Implemented dynamic `WalletNotifier` to calculate earnings from `ordersProvider`.

## Current State
- **Build**: Passing (`flutter analyze` 0 errors).
- **Status**: Production-ready MVP for demo.