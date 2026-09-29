import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/models/call_model.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_event.dart';
import '../bloc/call_state.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Missed, 2: Audio, 3: Video

  @override
  void initState() {
    super.initState();
    context.read<CallBloc>().add(FetchCallLogsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = [
      'common.all'.tr(),
      'calls.missed'.tr(),
      'calls.audio'.tr(),
      'calls.video'.tr(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'calls.historyTitle'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<CallBloc, CallState>(
        builder: (context, state) {
          var logs = state.callLogs;
          if (_selectedFilterIndex == 1) {
            logs = logs.where((e) => e.outcome == CallStatus.missed || e.outcome == CallStatus.declined).toList();
          } else if (_selectedFilterIndex == 2) {
            logs = logs.where((e) => e.type == CallType.audio).toList();
          } else if (_selectedFilterIndex == 3) {
            logs = logs.where((e) => e.type == CallType.video).toList();
          }

          return Column(
            children: [
              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: List.generate(filterTabs.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filterTabs[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilterIndex = index);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              // Call Log List
              Expanded(
                child: logs.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.phone_disabled_rounded,
                        title: 'No call logs found',
                        description: 'Your VoIP call history with shippers and drivers will appear here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isMissed = log.outcome == CallStatus.missed || log.outcome == CallStatus.declined;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Call Icon Indicator
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isMissed
                                        ? AppColors.rose.withValues(alpha: 0.12)
                                        : AppColors.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    log.type == CallType.video ? Icons.videocam_rounded : Icons.phone_rounded,
                                    color: isMissed ? AppColors.rose : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Caller & Timestamp
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        log.participantName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            log.direction == CallDirection.incoming
                                                ? Icons.call_received_rounded
                                                : Icons.call_made_rounded,
                                            size: 14,
                                            color: isMissed ? AppColors.rose : AppColors.emerald,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${DateFormat('MMM dd, HH:mm').format(log.timestamp)} • ${log.formattedDuration}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Direct Callback Button
                                IconButton(
                                  icon: Icon(
                                    log.type == CallType.video ? Icons.videocam_outlined : Icons.call_outlined,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Call back',
                                  onPressed: () {
                                    context.read<CallBloc>().add(
                                          StartCallRequested(
                                            receiverId: 'USR-CALL',
                                            receiverName: log.participantName,
                                            type: log.type,
                                          ),
                                        );
                                    context.push('/calls/active');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
