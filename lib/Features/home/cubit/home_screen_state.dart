import 'package:equatable/equatable.dart';

/// State for the Home Screen — holds active tab and carousel page index.
class HomeScreenState extends Equatable {
  final int activeTab; // 0 = Today, 1 = Discover
  final int activeCarouselPage; // 0‥carouselCount-1

  const HomeScreenState({this.activeTab = 0, this.activeCarouselPage = 0});

  HomeScreenState copyWith({int? activeTab, int? activeCarouselPage}) {
    return HomeScreenState(
      activeTab: activeTab ?? this.activeTab,
      activeCarouselPage: activeCarouselPage ?? this.activeCarouselPage,
    );
  }

  @override
  List<Object?> get props => [activeTab, activeCarouselPage];
}
