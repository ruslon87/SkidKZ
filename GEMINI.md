# GEMINI.md

## Project Status
**Date**: 2026-02-01
**Status**: Active Development
**Feature Set**: Buyer Marketplace Home

## Recent Changes
- **Core**: Added `riverpod` (2.6.1) and `state_notifier` (1.0.0) dependencies for robust state management.
- **Data**: Created `ProductRepository` with Firestore cursor-based pagination logic.
- **Models**: Added `Product` model (`lib/models/product.dart`) matching Firestore schema.
- **UI**: Implemented `HomePage` (`lib/features/home/home_page.dart`) with:
    -   Custom "Kaspi-like" Top Bar (Menu, Location, Search).
    -   Promo Banners (PageView).
    -   Categories (Horizontal List).
    -   Recently Viewed (Horizontal List).
    -   **Recommended for you**: Infinite scrolling horizontal list of products fetched from Firestore.
- **Routing**: Updated `AppRouter` to point `/buyer/home` to the new `HomePage`.
- **Theme**: Updated `AppTheme` to use Light Blue (`0xFF0277BD`) primary color and neutral background.

## Technical Details
- **State Management**: Using `StateNotifierProvider` for the Home Page logic to manage pagination state (`HomeState`).
- **Pagination**: Manual cursor-based pagination using `startAfterDocument` (via retrieving document snapshot by ID).
- **Constraints**: 
    -   No Firestore streams used for product list.
    -   Infinite scroll implemented horizontally as requested.

## Next Steps
- Implement actual Search functionality.
- Connect "Recently Viewed" to local storage or mock provider.
- Implement Product Detail navigation.
