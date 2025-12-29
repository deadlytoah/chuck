import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/upload_zone.dart';
import '../widgets/filter_bar.dart';
import '../widgets/bulk_actions.dart';
import '../widgets/items_grid.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final filter = ref.read(filterProvider);
        final sort = ref.read(sortProvider);
        await ref.read(itemsProvider.notifier).loadItems(filter: filter, sort: sort);
      } catch (e) {
        // Silent failure on initial load - user can tap refresh button to retry
        print('Initial load failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SafeArea(
              child: Padding(padding: EdgeInsets.all(16), child: UploadZone()),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FilterBar(),
            ),
            const Padding(padding: EdgeInsets.all(16), child: BulkActions()),
            const ItemsGrid(shrinkWrap: true),
          ],
        ),
      ),
    );
  }
}
