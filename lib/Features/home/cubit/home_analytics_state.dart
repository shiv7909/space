import 'package:equatable/equatable.dart';
import '../../../models/home_analytics_model.dart';

abstract class HomeAnalyticsState extends Equatable {
  const HomeAnalyticsState();

  @override
  List<Object?> get props => [];
}

class HomeAnalyticsInitial extends HomeAnalyticsState {}

class HomeAnalyticsLoading extends HomeAnalyticsState {}

class HomeAnalyticsLoaded extends HomeAnalyticsState {
  final HomeAnalytics analytics;

  const HomeAnalyticsLoaded(this.analytics);

  @override
  List<Object?> get props => [analytics];
}

class HomeAnalyticsError extends HomeAnalyticsState {
  final String message;

  const HomeAnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
