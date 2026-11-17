#!/usr/bin/env bash
# Checks the layering rules of docs/ARCHITECTURE.md (grep of the imports).
# Usage: scripts/check-layering.sh [--strict]  (without --strict: warnings, exit code 0)
cd "$(dirname "$0")/.." || exit 1
bad=0
check() { # folder, forbidden regex, description
  [ -d "$1" ] || return 0
  # Comment lines are not dependencies: drop them before judging.
  hits=$(grep -rnE "$2" "$1" --include='*.swift' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//')
  if [ -n "$hits" ]; then echo "VIOLATION [$3] in $1"; echo "$hits" | head -20; bad=1; fi
}
for d in mDone/Core/Models mDone/Domain; do
  check "$d" '^import (SwiftUI|UIKit|AppKit|SwiftData|EventKit)' "pure layer"
  check "$d" 'AppState|UserDefaults\.standard' "pure layer"
done
check mDone/Core/Networking '^import (SwiftUI|UIKit|AppKit)' "network layer without UI"
check mDone/DesignSystem 'AppState|SwiftData' "design system without state"
# Dependencies point downwards: neither Features nor DesignSystem know Platform,
# and DesignSystem, Domain and Core do not know Features (the Things types concerned).
check mDone/Features 'ThingsMac[A-Z]|ThingsQuickEntry|ThingsTypeTravel|ThingsRootView' "Features without Platform"
check mDone/DesignSystem 'ThingsMac[A-Z]|ThingsQuickEntry|ThingsTypeTravel|ThingsRootView|Things(List|Home)ViewModel' "design system without Platform or Features"
for d in mDone/Core mDone/Domain; do
  check "$d" 'Things(List|Home)ViewModel|ThingsRowMapper|ThingsQuickFindEngine|ThingsShortcutTable|ThingsMac[A-Z]' "low layer without Features or Platform"
done
check mDoneShared 'import mDone$|@testable' "shared code without the app"
if [ "$bad" = 1 ] && [ "$1" = "--strict" ]; then exit 1; fi
exit 0
