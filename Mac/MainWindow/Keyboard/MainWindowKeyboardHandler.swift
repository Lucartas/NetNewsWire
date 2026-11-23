//
//  MainWindowKeyboardHandler.swift
//  NetNewsWire
//
//  Created by Brent Simmons on 12/19/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import AppKit
import RSCore

@MainActor final class MainWindowKeyboardHandler: KeyboardDelegate {
	static let shared = MainWindowKeyboardHandler()
	let globalShortcuts: Set<KeyboardShortcut>

	init() {
		let f = Bundle.main.path(forResource: "GlobalKeyboardShortcuts", ofType: "plist")!
		let rawShortcuts = NSArray(contentsOfFile: f)! as! [[String: Any]]

		self.globalShortcuts = Set(rawShortcuts.compactMap { KeyboardShortcut(dictionary: $0) })
	}

	func keydown(_ event: NSEvent, in view: NSView) -> Bool {
		let key = KeyboardKey(with: event)
		if let matchingShortcut = KeyboardShortcut.findMatchingShortcut(in: globalShortcuts, key: key) {
			matchingShortcut.perform(with: view)
			return true
		}

		guard event.charactersIgnoringModifiers == "i",
			  event.modifierFlags.intersection([.shift, .option, .command, .control]).isEmpty,
			  view is TimelineTableView || view is DetailWebView,
			  let controller = view.window?.windowController as? MainWindowController,
			  controller.usesCompactLayout else {
			return false
		}

		if !event.isARepeat {
			controller.toggleCompactModeArticle()
		}
		return true
	}
}
