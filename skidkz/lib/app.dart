return GoRouter(
  initialLocation: '/buyer/home',
  refreshListenable: refresh,

  builder: (context, state, child) {
    return AppBackHandler(
      router: GoRouter.of(context),
      child: child,
    );
  },

  redirect: (context, state) {
    ...
  },
  ...
);
