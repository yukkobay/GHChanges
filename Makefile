dev:
	swift build; swift run

gen:
	swift package generate-xcodeproj

checkout:
	swift package update
	swift package generate-xcodeproj
