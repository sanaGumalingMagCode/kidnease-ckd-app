import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../food_assessment/domain/entities/dietary_assessment.dart';
import '../../../../shared/providers/providers.dart';

class AssessmentListWidget extends ConsumerStatefulWidget {
  final String userId;

  const AssessmentListWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<AssessmentListWidget> createState() =>
      _AssessmentListWidgetState();
}

class _AssessmentListWidgetState extends ConsumerState<AssessmentListWidget> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _riskLevelFilter;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreRepo = ref.watch(firestoreRepositoryProvider);

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(),

        // Assessment list
        Expanded(
          child: StreamBuilder<List<DietaryAssessment>>(
            stream: firestoreRepo.getAssessmentHistory(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              var assessments = snapshot.data ?? [];

              // Apply filters
              assessments = _applyFilters(assessments);

              if (assessments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ||
                                _riskLevelFilter != null ||
                                _dateRange != null
                            ? 'No matching assessments'
                            : 'No assessments yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isNotEmpty ||
                                _riskLevelFilter != null ||
                                _dateRange != null
                            ? 'Try adjusting your filters'
                            : 'Start scanning food to see your history',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: assessments.length,
                itemBuilder: (context, index) {
                  return _buildAssessmentCard(assessments[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search food name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 12),

            // Filter chips
            Wrap(
              spacing: 8,
              children: [
                // Risk level filter
                FilterChip(
                  label: Text(_riskLevelFilter ?? 'All Risk Levels'),
                  selected: _riskLevelFilter != null,
                  onSelected: (selected) {
                    _showRiskLevelFilter();
                  },
                ),

                // Date range filter
                FilterChip(
                  label: Text(_dateRange != null
                      ? '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}'
                      : 'All Dates'),
                  selected: _dateRange != null,
                  onSelected: (selected) {
                    _showDateRangePicker();
                  },
                ),

                // Clear filters
                if (_riskLevelFilter != null || _dateRange != null)
                  ActionChip(
                    label: const Text('Clear Filters'),
                    onPressed: () {
                      setState(() {
                        _riskLevelFilter = null;
                        _dateRange = null;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard(DietaryAssessment assessment) {
    final isHighRisk = assessment.riskLevel == RiskLevel.highRisk;
    final badgeColor = isHighRisk ? Colors.red : Colors.green;
    final badgeIcon = isHighRisk ? Icons.warning_amber : Icons.check_circle;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showAssessmentDetails(assessment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Risk badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 16, color: badgeColor),
                        const SizedBox(width: 4),
                        Text(
                          assessment.riskLevel.displayText,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Timestamp
                  Text(
                    DateFormat('MMM d, h:mm a').format(assessment.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Food name
              Text(
                assessment.detectedFoodName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Explanation preview
              Text(
                assessment.explanationText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DietaryAssessment> _applyFilters(List<DietaryAssessment> assessments) {
    var filtered = assessments;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((a) =>
              a.detectedFoodName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Risk level filter
    if (_riskLevelFilter != null) {
      filtered = filtered
          .where((a) => a.riskLevel.displayText == _riskLevelFilter)
          .toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((a) {
        return a.timestamp.isAfter(_dateRange!.start) &&
            a.timestamp.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  void _showRiskLevelFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Risk Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<String?>(
                value: null,
                groupValue: _riskLevelFilter,
                onChanged: (value) {
                  setState(() => _riskLevelFilter = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('High Risk'),
              leading: Radio<String?>(
                value: 'High Risk',
                groupValue: _riskLevelFilter,
                onChanged: (value) {
                  setState(() => _riskLevelFilter = value);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Safe'),
              leading: Radio<String?>(
                value: 'Safe',
                groupValue: _riskLevelFilter,
                onChanged: (value) {
                  setState(() => _riskLevelFilter = value);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _showAssessmentDetails(DietaryAssessment assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assessment.detectedFoodName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Risk level
              Row(
                children: [
                  Icon(
                    assessment.riskLevel == RiskLevel.highRisk
                        ? Icons.warning_amber
                        : Icons.check_circle,
                    color: assessment.riskLevel == RiskLevel.highRisk
                        ? Colors.red
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    assessment.riskLevel.displayText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: assessment.riskLevel == RiskLevel.highRisk
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Timestamp
              Text(
                'Scanned: ${DateFormat('MMMM d, y \'at\' h:mm a').format(assessment.timestamp)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Explanation
              const Text(
                'Explanation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(assessment.explanationText),
              const SizedBox(height: 16),

              // Filipino alternatives
              if (assessment.filipinoAlternatives.isNotEmpty) ...[
                const Text(
                  'Filipino Alternatives:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...assessment.filipinoAlternatives.map((alt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(alt)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
