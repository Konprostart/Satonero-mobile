import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:satonero_mobile/core/app_theme.dart';
import 'package:satonero_mobile/core/config.dart';
import 'package:satonero_mobile/features/logs/logs_provider.dart';
import 'package:satonero_mobile/features/logs/widgets/logs_actions_menu.dart';
import 'package:satonero_mobile/features/settings/settings_provider.dart';
import 'package:satonero_mobile/generated/l10n.dart';
import 'package:satonero_mobile/services/logger_service.dart';
import 'package:satonero_mobile/shared/widgets/mostro_switch.dart';
import 'package:satonero_mobile/shared/utils/datetime_extensions_utils.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> with WidgetsBindingObserver {
  String? _selectedLevel;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final showButton = _scrollController.offset > 200 && maxScroll > 200;
      if (showButton != _showScrollToTop) {
        setState(() => _showScrollToTop = showButton);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _toggleLogging(bool value) async {
    if (value) {
      await _showPerformanceWarning();
    } else {
      await _disableLoggingAndSave();
    }
  }

  void _enableLogging() {
    MemoryLogOutput.isLoggingEnabled = true;
    ref.read(settingsProvider.notifier).updateLoggingEnabled(true);
  }

  void _disableLogging() {
    MemoryLogOutput.isLoggingEnabled = false;
    ref.read(settingsProvider.notifier).updateLoggingEnabled(false);
  }

  Future<void> _showPerformanceWarning() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.colors(context).cardBackground,
        title: Text(
          S.of(context)!.performanceWarning,
          style: TextStyle(color: AppTheme.colors(context).textPrimary),
        ),
        content: Text(
          S.of(context)!.performanceWarningMessage,
          style: TextStyle(color: AppTheme.colors(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context)!.enable),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _enableLogging();
    }
  }

  Future<void> _disableLoggingAndSave() async {
    if (mounted) {
      _disableLogging();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isLoggingEnabled = settings.isLoggingEnabled;
    final filter = LogsFilter(
      levelFilter: _selectedLevel,
      searchQuery: _searchQuery,
    );
    final allLogs = ref.watch(logsProvider);
    final logs = ref.watch(filteredLogsProvider(filter));

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.colors(context).scaffoldBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              S.of(context)!.logsReport,
              style: TextStyle(
                color: AppTheme.colors(context).textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: IconThemeData(color: AppTheme.colors(context).textPrimary),
            actions: [
              LogsActionsMenu(),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildStatsHeader(allLogs.length, logs.length, isLoggingEnabled),
                _buildSearchBar(),
                _buildFilterChips(),
                Expanded(
                  child: logs.isEmpty
                      ? _buildEmptyState()
                      : _buildLogsList(logs),
                ),
              ],
            ),
          ),
        ),
        if (_showScrollToTop && logs.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.colors(context).accent,
              onPressed: _scrollToTop,
              child: Icon(
                Icons.arrow_upward,
                color: AppTheme.colors(context).textPrimary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatsHeader(int totalCount, int filteredCount, bool isLoggingEnabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context)!.logCapture,
                      style: TextStyle(
                        color: AppTheme.colors(context).textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggingEnabled
                          ? S.of(context)!.capturingLogs
                          : S.of(context)!.captureDisabled,
                      style: TextStyle(
                        color: isLoggingEnabled
                            ? AppTheme.colors(context).accent
                            : AppTheme.colors(context).textInactive,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              MostroSwitch(
                value: isLoggingEnabled,
                onChanged: _toggleLogging,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filteredCount == totalCount
                    ? S.of(context)!.totalLogs(totalCount)
                    : '$filteredCount / ${S.of(context)!.totalLogs(totalCount)}',
                style: TextStyle(
                  color: AppTheme.colors(context).textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                S.of(context)!.maxEntries(Config.logMaxEntries),
                style: TextStyle(
                  color: AppTheme.colors(context).textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.colors(context).cardBackground,
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: AppTheme.colors(context).textPrimary),
        decoration: InputDecoration(
          hintText: S.of(context)!.searchLogs,
          hintStyle: TextStyle(color: AppTheme.colors(context).textSecondary),
          prefixIcon: Icon(Icons.search, color: AppTheme.colors(context).textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.colors(context).textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _showScrollToTop = false;
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(0);
                      }
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.colors(context).inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _showScrollToTop = false;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.colors(context).cardBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(S.of(context)!.allLevels, null),
            const SizedBox(width: 8),
            _buildFilterChip(S.of(context)!.errors, 'error'),
            const SizedBox(width: 8),
            _buildFilterChip(S.of(context)!.warnings, 'warning'),
            const SizedBox(width: 8),
            _buildFilterChip(S.of(context)!.info, 'info'),
            const SizedBox(width: 8),
            _buildFilterChip(S.of(context)!.debug, 'debug'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? levelFilter) {
    final isSelected = _selectedLevel == levelFilter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLevel = selected ? levelFilter : null;
          _showScrollToTop = false;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      },
      backgroundColor: AppTheme.colors(context).inputBackground,
      selectedColor: AppTheme.colors(context).info.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.colors(context).info : AppTheme.colors(context).textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.colors(context).info : Colors.white.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: AppTheme.colors(context).textInactive,
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context)!.noLogsAvailable,
            style: TextStyle(
              color: AppTheme.colors(context).textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              S.of(context)!.logsWillAppearHere,
              style: TextStyle(
                color: AppTheme.colors(context).textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(List<LogEntry> logs) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: bottomInset + 64),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[logs.length - 1 - index];
        return _buildLogItem(log);
      },
    );
  }

  Widget _buildLogItem(LogEntry log) {
    final color = _getLogLevelColor(log.level);
    final icon = _getLogLevelIcon(log.level);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.colors(context).cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                log.level.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${log.service}:${log.line}',
                style: TextStyle(
                  color: AppTheme.colors(context).textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(log.timestamp),
                style: TextStyle(
                  color: AppTheme.colors(context).textInactive,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: TextStyle(
              color: AppTheme.colors(context).textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(Level level) {
    switch (level) {
      case Level.error:
        return AppTheme.colors(context).danger;
      case Level.warning:
        return AppTheme.colors(context).warning;
      case Level.info:
        return AppTheme.colors(context).info;
      case Level.debug:
        return AppTheme.colors(context).textSecondary;
      default:
        return AppTheme.colors(context).textSecondary;
    }
  }

  IconData _getLogLevelIcon(Level level) {
    switch (level) {
      case Level.error:
        return Icons.error;
      case Level.warning:
        return Icons.warning;
      case Level.info:
        return Icons.info;
      case Level.debug:
        return Icons.bug_report;
      default:
        return Icons.circle;
    }
  }

  String _formatTime(DateTime timestamp) {
    return timestamp.timeAgoWithLocale(context);
  }
}
