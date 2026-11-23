//
//  SingleColumnViewController.swift
//  NetNewsWire
//

import AppKit

/// Hosts the timeline or reader in the content pane next to the sidebar.
final class SingleColumnViewController: NSViewController {

	private let backButton: NSButton
	private var pane: NSViewController?
	private var paneConstraints = [NSLayoutConstraint]()

	init(backTarget: AnyObject, backAction: Selector) {
		backButton = NSButton(title: "", target: backTarget, action: backAction)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		view = NSView()
		backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
		backButton.imagePosition = .imageOnly
		backButton.bezelStyle = .toolbar
		backButton.toolTip = NSLocalizedString("Back to Articles", comment: "Back button in Compact Mode")
		backButton.setAccessibilityLabel(NSLocalizedString("Back to Articles", comment: "Back button in Compact Mode"))
		backButton.translatesAutoresizingMaskIntoConstraints = false
		backButton.isHidden = true
		view.addSubview(backButton)
		NSLayoutConstraint.activate([
			backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
			backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12)
		])
	}

	func show(_ controller: NSViewController, showsBackButton: Bool) {
		guard pane !== controller else {
			return
		}
		removePane()
		let container = view
		backButton.isHidden = !showsBackButton

		addChild(controller)
		let paneView = controller.view
		paneView.translatesAutoresizingMaskIntoConstraints = false
		container.addSubview(paneView, positioned: .below, relativeTo: backButton)

		let safeArea = container.safeAreaLayoutGuide
		let topAnchor = showsBackButton ? backButton.bottomAnchor : safeArea.topAnchor
		paneConstraints = [
			paneView.topAnchor.constraint(equalTo: topAnchor, constant: showsBackButton ? 8 : 0),
			paneView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
			paneView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
			paneView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
		]
		NSLayoutConstraint.activate(paneConstraints)
		pane = controller
	}

	func removePane() {
		NSLayoutConstraint.deactivate(paneConstraints)
		paneConstraints.removeAll()
		pane?.view.removeFromSuperview()
		pane?.removeFromParent()
		pane = nil
	}
}
