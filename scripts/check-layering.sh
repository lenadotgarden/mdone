#!/usr/bin/env bash
# Verifie les regles de couches de docs/ARCHITECTURE.md (grep des imports).
# Usage: scripts/check-layering.sh [--strict]  (sans --strict: avertissements, code retour 0)
cd "$(dirname "$0")/.." || exit 1
bad=0
check() { # dossier, regex interdite, description
  [ -d "$1" ] || return 0
  # Comment lines are not dependencies: drop them before judging.
  hits=$(grep -rnE "$2" "$1" --include='*.swift' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//')
  if [ -n "$hits" ]; then echo "VIOLATION [$3] dans $1"; echo "$hits" | head -20; bad=1; fi
}
for d in mDone/Core/Models mDone/Domain; do
  check "$d" '^import (SwiftUI|UIKit|AppKit|SwiftData|EventKit)' "couche pure"
  check "$d" 'AppState|UserDefaults\.standard' "couche pure"
done
check mDone/Core/Networking '^import (SwiftUI|UIKit|AppKit)' "reseau sans UI"
check mDone/DesignSystem 'AppState|SwiftData' "design system sans etat"
# Les dependances vont vers le bas: ni Features ni DesignSystem ne connaissent Platform,
# ni DesignSystem, Domain, Core ne connaissent Features (types Things concernes).
check mDone/Features 'ThingsMac[A-Z]|ThingsQuickEntry|ThingsTypeTravel|ThingsRootView' "Features sans Platform"
check mDone/DesignSystem 'ThingsMac[A-Z]|ThingsQuickEntry|ThingsTypeTravel|ThingsRootView|Things(List|Home)ViewModel' "design system sans Platform ni Features"
for d in mDone/Core mDone/Domain; do
  check "$d" 'Things(List|Home)ViewModel|ThingsRowMapper|ThingsQuickFindEngine|ThingsShortcutTable|ThingsMac[A-Z]' "bas niveau sans Features ni Platform"
done
check mDoneShared 'import mDone$|@testable' "partage sans app"
if [ "$bad" = 1 ] && [ "$1" = "--strict" ]; then exit 1; fi
exit 0
