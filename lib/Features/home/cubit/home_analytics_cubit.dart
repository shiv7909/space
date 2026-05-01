import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/home_analytics_model.dart';
import '../../../services/space_service.dart';
import 'home_analytics_state.dart';

class HomeAnalyticsCubit extends Cubit<HomeAnalyticsState> {
  final SpaceService _spaceService;

  HomeAnalyticsCubit(this._spaceService) : super(HomeAnalyticsInitial());

  Future<void> loadAnalytics() async {
    emit(HomeAnalyticsLoading());
    try {
      final data = await _spaceService.getMyFullAnalytics();
      if (data.isEmpty) {
        emit(const HomeAnalyticsError('No data available'));
        return;
      }
      final analytics = HomeAnalytics.fromJson(data);
      emit(HomeAnalyticsLoaded(analytics));
    } catch (e) {
      emit(HomeAnalyticsError('Failed to load analytics: $e'));
    }
  }

  Future<void> refresh() => loadAnalytics();
}
