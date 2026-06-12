import 'package:flutter/material.dart';
import '../upload/upload_screen.dart';
import 'package:flutter/scheduler.dart'; // Added for the refresh trigger
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // SAFETY FIX: Force a refresh of history data the moment the Home Screen is built.
    // This ensures that even if login finishes early, we re-verify the data here.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchHistoryData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final history = provider.history;
    final bool isMobile = Responsive.isMobile(context);

    final String firstInitial = user?.firstName.isNotEmpty == true
        ? user!.firstName[0].toUpperCase()
        : 'U';
    final String lastInitial = user?.lastName.isNotEmpty == true
        ? user!.lastName[0].toUpperCase()
        : '';
    final String initials = '$firstInitial$lastInitial';

    int totalMarkers = 0;
    for (var record in history) {
      totalMarkers += record.markers.length;
    }

    final filteredHistory = history.where((record) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final nameMatch = record.filename.toLowerCase().contains(query);
      final dateMatch = record.dateUploaded.toLowerCase().contains(query);
      final descMatch = record.description.toLowerCase().contains(query);
      return nameMatch || dateMatch || descMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
                vertical: isMobile ? 16 : 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Image Review',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${history.length} images  •  $totalMarkers markers',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    radius: isMobile ? 20 : 24,
                    backgroundColor: AppColors.background,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            Text(
              'Welcome back, ${user?.firstName ?? 'User'}!',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Here is an overview of your recent clinical image reviews.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 40),

            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText:
                          'Search by filename, date, or clinical notes...',
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryButton,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (provider.compareSelection.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryButton.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryButton.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.compare,
                            color: AppColors.primaryButton,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Longitudinal Comparison Mode',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${provider.compareSelection.length} of 2 images selected',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (provider.compareSelection.length == 2)
                            CustomButton(
                              text: provider.isLoading
                                  ? 'Processing...'
                                  : 'Run Comparison',
                              width: isMobile ? 120 : 160,
                              onPressed: provider.isLoading
                                  ? () {}
                                  : () async {
                                      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return ComparisonDateDialog(
              selectedImages: provider.history.where((img) => provider.compareSelection.contains(img.id)).toList(),
            );
          }
        );
                                      if (context.mounted) {
                                        context.go('/upload');
                                      }
                                    },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filteredHistory.isEmpty && _searchQuery.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No results found.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (history.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 40,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No recent images found.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Go to Workspace to upload a new image.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filteredHistory.map((record) {
                      final bool isSelected = provider.compareSelection
                          .contains(record.id);
                      final bool disableCheckbox =
                          provider.compareSelection.length == 2 && !isSelected;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryButton.withValues(alpha: 0.05)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryButton
                                : AppColors.borderLight,
                          ),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: AppColors.primaryButton,
                                        onChanged: disableCheckbox
                                            ? null
                                            : (val) => provider
                                                  .toggleCompareSelection(
                                                    record.id,
                                                  ),
                                      ),
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderLight,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: record.imageBytes != null
                                              ? Image.memory(
                                                  record.imageBytes!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: AppColors.background,
                                                  child: const Icon(
                                                    Icons.image,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.filename,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Uploaded: ${record.dateUploaded}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: CustomButton(
                                          text: 'Review',
                                          onPressed: () {
                                            provider.setActiveImage(record);
                                            context.go('/upload');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => provider
                                            .removeImageFromHistory(record.id),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppColors.primaryButton,
                                    onChanged: disableCheckbox
                                        ? null
                                        : (val) =>
                                              provider.toggleCompareSelection(
                                                record.id,
                                              ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: record.imageBytes != null
                                          ? Image.memory(
                                              record.imageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppColors.background,
                                              child: const Icon(
                                                Icons.image,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          record.filename,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Uploaded: ${record.dateUploaded}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: CustomButton(
                                          text: 'Review',
                                          onPressed: () {
                                            provider.setActiveImage(record);
                                            context.go('/upload');
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.error,
                                        ),
                                        onPressed: () => provider
                                            .removeImageFromHistory(record.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
