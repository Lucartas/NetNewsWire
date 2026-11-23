//
//  WindowLayout.swift
//  NetNewsWire
//

enum WindowLayout {
	case standard
	case column
	case compact

	var timelineLayout: TimelineLayout {
		self == .column ? .column : .standard
	}
}
