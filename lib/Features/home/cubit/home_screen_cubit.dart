import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_screen_state.dart';

/// Cubit that manages the Home Screen tab + carousel state.
///
/// Owns the auto-scroll timer so the widget tree doesn't need setState
/// for carousel page changes — scoped BlocBuilder rebuilds only the
/// widgets that actually depend on [activeCarouselPage] or [activeTab].
class HomeScreenCubit extends Cubit<HomeScreenState> {
  Timer? _autoScrollTimer;
  static const int carouselCount = 3;

  HomeScreenCubit() : super(const HomeScreenState());

  // ── Tab ──────────────────────────────────────────────────────────────

  void setTab(int index) {
    if (index != state.activeTab) {
      emit(state.copyWith(activeTab: index));
    }
  }

  // ── Carousel page ────────────────────────────────────────────────────

  void setCarouselPage(int page) {
    if (page != state.activeCarouselPage) {
      emit(state.copyWith(activeCarouselPage: page));
    }
  }

  /// Call from the widget's initState to begin auto-scrolling.
  /// [onAnimate] is invoked every 4 s with the *next* page index so the
  /// widget can call `pageController.animateToPage(...)`.
  /// ✅ OPTIMIZATION: Only updates UI through callback, NOT through state emissions
  void startAutoScroll(void Function(int nextPage) onAnimate) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final next = (state.activeCarouselPage + 1) % carouselCount;
      // ✅ Call the widget callback directly to animate the carousel
      // This DOES NOT emit state — the page change is handled by PageView.onPageChanged
      onAnimate(next);
      // ✅ Only update internal state when user manually swipes (see onPageChanged in widget)
    });
  }

  /// Restart auto-scroll (e.g. after a manual swipe).
  void restartAutoScroll(void Function(int nextPage) onAnimate) {
    startAutoScroll(onAnimate);
  }

  @override
  Future<void> close() {
    _autoScrollTimer?.cancel();
    return super.close();
  }
}
