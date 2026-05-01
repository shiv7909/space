// // filepath: d:\habitz\lib\Features\discover\screens\discover_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../../../core/theme/app_theme.dart';
// import '../cubit/active_people_cubit.dart';
// import '../cubit/discover_cubit.dart';
// import '../cubit/discover_state.dart';
// import '../models/discover_models.dart';
// import '../widgets/discover_content.dart';
// import '../widgets/discover_empty_state.dart';
// import '../widgets/discover_search_bar.dart';
// import '../widgets/discover_filter_tabs.dart';
// import '../widgets/active_people_section.dart';
// import '../widgets/space_card.dart';
// import '../widgets/trending_carousel.dart';
// import '../widgets/feed_header.dart';
// import '../widgets/space_preview_sheet.dart';
//
// class DiscoverScreen extends StatefulWidget {
//   const DiscoverScreen({super.key});
//
//   @override
//   State<DiscoverScreen> createState() => _DiscoverScreenState();
// }
//
// class _DiscoverScreenState extends State<DiscoverScreen> {
//   late final DiscoverCubit _cubit;
//   late final ActivePeopleCubit _activePeopleCubit;
//   final _searchCtrl = TextEditingController();
//   final _scrollCtrl = ScrollController();
//   Position? _position;
//
//   static const _filters = [
//     FilterTabItem(key: 'all', label: 'All'),
//     FilterTabItem(key: 'nearby', label: 'Nearby', icon: Icons.location_on_rounded),
//     FilterTabItem(key: 'trending', label: 'Trending', icon: Icons.local_fire_department_rounded),
//     FilterTabItem(key: 'crews', label: 'Crews', icon: Icons.groups_rounded),
//     FilterTabItem(key: 'challenges', label: 'Challenges', icon: Icons.flag_rounded),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _cubit = DiscoverCubit(Supabase.instance.client);
//     _activePeopleCubit = ActivePeopleCubit(Supabase.instance.client);
//     _initLocationAndLoad();
//     _scrollCtrl.addListener(_onScroll);
//   }
//
//   Future<void> _initLocationAndLoad() async {
//     // Try to get location — gracefully fails if not permitted
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.always ||
//           permission == LocationPermission.whileInUse) {
//         _position = await Geolocator.getCurrentPosition(
//           locationSettings: const LocationSettings(
//             accuracy: LocationAccuracy.low,
//           ),
//         );
//       }
//     } catch (_) {}
//
//     if (mounted) {
//       _cubit.loadAll(_position);
//       _activePeopleCubit.load(
//         lat: _position?.latitude,
//         lng: _position?.longitude,
//       );
//     }
//   }
//
//   void _onScroll() {
//     if (_scrollCtrl.position.pixels >=
//         _scrollCtrl.position.maxScrollExtent - 300) {
//       final state = _cubit.state;
//       if (!state.isLoadingMore && !state.isLoading && state.hasMore) {
//         _cubit.fetchSpaces(pos: _position, loadMore: true);
//       }
//     }
//   }
//
//   Future<void> _handleJoinRequest(DiscoverSpace space) async {
//     // Show preview sheet first
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) => SpacePreviewSheet(
//         space: space,
//         onJoin: () => _processJoin(space.spaceId),
//       ),
//     );
//   }
//
//   Future<void> _processJoin(String spaceId) async {
//     final result = await _cubit.requestToJoin(spaceId);
//     if (!mounted) return;
//     switch (result) {
//       case JoinSuccess():
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Request sent! 🙌'),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           ),
//         );

//       case JoinError(:final message):
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           ),
//         );
//     }
//   }
//
//   @override
//   void dispose() {
//     _cubit.close();
//     _activePeopleCubit.close();
//     _searchCtrl.dispose();
//     _scrollCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider.value(value: _cubit),
//         BlocProvider.value(value: _activePeopleCubit),
//       ],
//       child: Scaffold(
//         backgroundColor: AppTheme.background,
//         body: SafeArea(
//           child: BlocBuilder<DiscoverCubit, DiscoverState>(
//             builder: (context, state) {
//               if (state.isLoading && state.spaces.isEmpty) {
//                 return const Center(
//                   child: SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2.5,
//                       color: AppTheme.onBackground,
//                     ),
//                   ),
//                 );
//               }
//
//               if (state.error != null && state.spaces.isEmpty) {
//                 return Center(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text('😕', style: TextStyle(fontSize: 48)),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Something went wrong',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 16),
//                       TextButton(
//                         onPressed: () => _cubit.refresh(_position),
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               return RefreshIndicator(
//                 onRefresh: () => _cubit.refresh(_position),
//                 color: AppTheme.primaryColor,
//                 child: CustomScrollView(
//                   controller: _scrollCtrl,
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   slivers: [
//                     // ── Search bar ───────────────────────────────────────
//                     SliverPersistentHeader(
//                       pinned: true,
//                       delegate: _SearchBarDelegate(
//                         controller: _searchCtrl,
//                         onChanged: (q) => _cubit.search(q, _position),
//                       ),
//                     ),
//
//                     // ── Filter tabs ──────────────────────────────────────
//                     SliverPersistentHeader(
//                       pinned: true,
//                       delegate: _FilterTabsDelegate(
//                         filters: _filters,
//                         active: state.activeFilter,
//                         onTap: (f) => _cubit.setFilter(f, _position),
//                       ),
//                     ),
//
//                     // ── Active people ────────────────────────────────────
//                     const SliverToBoxAdapter(
//                       child: ActivePeopleSection(),
//                     ),
//
//                     // ── Trending carousel ────────────────────────────────
//                     if (state.trendingSpaces.isNotEmpty)
//                       SliverToBoxAdapter(
//                         child: TrendingCarousel(
//                           spaces: state.trendingSpaces,
//                           onRequest: _handleJoinRequest,
//                         ),
//                       ),
//
//                     // ── Feed header ──────────────────────────────────────
//                     SliverToBoxAdapter(
//                       child: FeedHeader(
//                         filter: state.activeFilter,
//                         totalResults: state.total,
//                       ),
//                     ),
//
//                     // ── Empty state ──────────────────────────────────────
//                     if (state.spaces.isEmpty && !state.isLoading)
//                       SliverFillRemaining(
//                         hasScrollBody: false,
//                         child: DiscoverEmptyState(
//                           filter: state.activeFilter,
//                           searchQuery: state.searchQuery,
//                         ),
//                       )
//                     else ...[
//                       // ── Space card list ──────────────────────────────
//                       SliverList(
//                         delegate: SliverChildBuilderDelegate(
//                           (ctx, i) {
//                             if (i >= state.spaces.length) {
//                               return state.isLoadingMore
//                                   ? const Padding(
//                                       padding: EdgeInsets.all(24),
//                                       child: Center(
//                                         child: SizedBox(
//                                           width: 20,
//                                           height: 20,
//                                           child: CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                             color: AppTheme.onSurfaceVariant,
//                                           ),
//                                         ),
//                                       ),
//                                     )
//                                   : const SizedBox(height: 100); // bottom padding for nav bar
//                             }
//                             return SpaceCard(
//                               space: state.spaces[i],
//                               onRequest: () => _handleJoinRequest(
//                                 state.spaces[i],
//                               ),
//                             );
//                           },
//                           childCount: state.spaces.length + 1,
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
//   _SearchBarDelegate({
//     required this.controller,
//     required this.onChanged,
//   });
//
//   final TextEditingController controller;
//   final ValueChanged<String> onChanged;
//
//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return Material(
//       color: AppTheme.background,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 onChanged: onChanged,
//                 decoration: InputDecoration(
//                   hintText: 'Search spaces, people, or topics',
//                   hintStyle: TextStyle(color: AppTheme.onBackground.withOpacity(0.6)),
//                   filled: true,
//                   fillColor: AppTheme.surface,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   prefixIcon: const Icon(Icons.search_rounded),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             IconButton(
//               onPressed: () {
//                 controller.clear();
//                 onChanged('');
//               },
//               icon: const Icon(Icons.clear_rounded),
//               color: AppTheme.onBackground,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   double get maxExtent => 72;
//
//   @override
//   double get minExtent => 72;
//
//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
//     return true;
//   }
// }
//
// class _FilterTabsDelegate extends SliverPersistentHeaderDelegate {
//   _FilterTabsDelegate({
//     required this.filters,
//     required this.active,
//     required this.onTap,
//   });
//
//   final List<FilterTabItem> filters;
//   final String active;
//   final ValueChanged<String> onTap;
//
//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return Material(
//       color: AppTheme.background,
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 4),
//         child: Row(
//           children: [
//             for (final filter in filters)
//               Expanded(
//                 child: InkWell(
//                   onTap: () => onTap(filter.key),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         bottom: BorderSide(
//                           color: active == filter.key
//                               ? AppTheme.primaryColor
//                               : Colors.transparent,
//                           width: 2,
//                         ),
//                       ),
//                     ),
//                     child: Center(
//                       child: Text(
//                         filter.label,
//                         style: TextStyle(
//                           color: active == filter.key
//                               ? AppTheme.primaryColor
//                               : AppTheme.onBackground,
//                           fontWeight: active == filter.key
//                               ? FontWeight.bold
//                               : FontWeight.normal,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   double get maxExtent => 56;
//
//   @override
//   double get minExtent => 56;
//
//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
//     return true;
//   }
// }
