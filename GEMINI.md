# SkidKZ Project

## Frameworks & Languages
- **Flutter** (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: GoRouter (`go_router`)
- **UI Components**: Material 3

## Project Structure
- `lib/core`: Core widgets and router.
- `lib/data`: Models and Repositories (Mock).
- `lib/features`: Feature-based folders (auth, buyer, seller, wanghong, admin).

## Recent Changes (Refinement Phase)
- **Unification of Models**:
  - `Product` model updated: `id`, `name`, `category`, `retailPrice`, `sellerPrice`, `status`, `isService`.
  - `Order` model updated: `id`, `product`, `buyerPhone`, `promoCode`, `customerPrice`, `sellerPayout`, `margin`, `wanghunEarning`, `platformEarning`, `createdAt`, `holdUntil`, `status`.
- **UI Updates**:
  - Updated all screens to use new model fields (`name` instead of `title`).
  - Implemented Russian localization for all new screens.
  - Fixed `SellerAddProductScreen` with proper price calculation logic.
- **Verification**:
  - Passed `flutter analyze` with 0 issues.
  - Ready for build (requires Android SDK).

## Next Steps
- Connect to real backend.
- Implement real payment gateway.
- Add push notifications.
