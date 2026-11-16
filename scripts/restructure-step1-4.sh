#!/usr/bin/env bash
# Deplacements mecaniques (docs/architecture-audit/04, etapes 1 a 4). Idempotent: ignore les fichiers absents.
set -e
cd "$(dirname "$0")/../mDone"
mv_() { dest="$1"; shift; mkdir -p "$dest"; for f in "$@"; do [ -e "$f" ] && git mv "$f" "$dest/"; done; true; }
mv_ Core/Models Models/{VTask,Project,Bucket,User,TaskRelation,APIModels,AuthOptions,ServerInfo,VikunjaVersion,VNotification,Label,HexColor,CalendarEvent,ProjectHierarchy}.swift
mv_ Core/Sync Models/QueuedTaskEdit.swift Services/{SyncService,NetworkMonitor,LiveListRefresh}.swift
mv_ Domain/Repeat Models/TaskRecurrence.swift
mv_ Domain/Scheduling Models/TaskOccurrence.swift App/QuickSchedule.swift
mv_ Domain/Filtering Models/TaskPositioning.swift App/{AdvancedTaskFilter,TaskSortOrder}.swift
mv_ Domain/Focus Models/FocusRun.swift Services/{FocusHistoryQuery,FocusDurationFormatter}.swift
mv_ Core/Networking Services/{APIClient,Endpoint,TaskService,ProjectService,LabelService,UserService,NotificationService,ServerInfoService,AuthService,JWTHelpers,ServerURL,OIDCLogin,WebAuthenticator,TaskLink,CalendarService}.swift
mv_ Core/Persistence Services/CacheService.swift App/ModelStoreBootstrap.swift
mv_ Domain/Parser Services/{SmartTaskParser,EstimateMarker,EstimateSuggester,DescriptionMarkup,DescriptionChecklist}.swift
mv_ Platform/iOS Services/{FocusManager,FocusOutboxService}.swift Views/Components/ShakeDetector.swift Views/MainTabView.swift
mv_ Core/Preferences Services/FocusSyncConfig.swift App/{CalendarPreferences,CalendarSelection,DefaultDueTimePreference,DefaultProjectPreference,NewTaskDueDatePreference,ProjectViewPreference,SmartParsingPreference,TaskListDensity,TeamFeaturesPreference}.swift
mv_ Features/QuickAdd Views/Tasks/QuickAddBar.swift
mv_ Features/TaskDetail Views/Tasks/{TaskDetailSheet,TaskRelationsSections,TaskLabelsSection,TaskAssigneesSection,DescriptionChecklistView,RichTextRendering,DescriptionEditHint,InlineTaskDetail}.swift Views/Components/{EstimatePicker,ReminderEditor,TaskScheduleEditor,TaskDateRangeMetadata,TaskShareButtons}.swift
mv_ Features/TaskList Views/Tasks/{TaskListScreen,SmartListSection}.swift Views/Components/{TaskSortMenu,TaskFilterSheet,FilterBar}.swift
mv_ DesignSystem/Components Views/Tasks/TaskRow.swift Views/Components/{ColorExtension,LabelChip,PriorityBadge,ProjectColorDot,ColorSwatchPicker,EmptyStateView,LoadingOverlay,ErrorBanner}.swift
mv_ Features/Projects Views/Projects/{ArchivedProjectsScreen,ProjectEditSheet,ProjectListScreen,ProjectRow}.swift
mv_ Features/Board Views/Projects/ProjectBoardView.swift
mv_ Features/Calendar Views/Calendar/*.swift
mv_ Features/Focus Views/Focus/*.swift Views/Components/FocusHistoryRow.swift
mv_ Features/Settings Views/Settings/*.swift
mv_ Features/Setup Views/Setup/*.swift
mv_ Features/Notifications Views/Notifications/*.swift
mv_ Platform/macOS Views/Mac/*.swift
rmdir Models Services Views/* Views 2>/dev/null || true
