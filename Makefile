dev:
	swift build; swift run

open:
	swift package generate-xcodeproj
	sleep 2
	open ./GHChanges.xcodeproj

checkout:
	swift package update
	swift package generate-xcodeproj
