//
//  SingleColumnViewController.swift
//  NetNewsWire
//

import AppKit
import QuartzCore

/// Hosts the timeline or reader in the content pane next to the sidebar.
final class SingleColumnViewController: NSViewController {

	private struct Pane {
		let id = UUID()
		let controller: NSViewController
		let host: NSView
		let showsBackButton: Bool
		let horizontalPosition: NSLayoutConstraint
		let constraints: [NSLayoutConstraint]
	}

	private final class PaneHost: NSView {
		override func hitTest(_ point: NSPoint) -> NSView? {
			let hit = super.hitTest(point)
			return hit === self ? nil : hit
		}
	}

	private static let slideAnimationKey = "compactModeSlide"

	private let backButton: NSButton
	private let timelineHost = PaneHost()
	private let articleHost = PaneHost()
	private lazy var timelinePosition = timelineHost.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
	private lazy var articlePosition = articleHost.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor)
	private var pane: Pane?
	private var outgoingPane: Pane?

	init(backTarget: AnyObject, backAction: Selector) {
		backButton = NSButton(title: "", target: backTarget, action: backAction)
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func loadView() {
		view = NSView()
		view.wantsLayer = true
		view.clipsToBounds = true
		for (host, position) in [(timelineHost, timelinePosition), (articleHost, articlePosition)] {
			host.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(host)
			NSLayoutConstraint.activate([
				position,
				host.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
				host.topAnchor.constraint(equalTo: view.topAnchor),
				host.bottomAnchor.constraint(equalTo: view.bottomAnchor)
			])
		}
		backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
		backButton.imagePosition = .imageOnly
		backButton.bezelStyle = .toolbar
		backButton.toolTip = NSLocalizedString("Back to Articles", comment: "Back button in Compact Mode")
		backButton.setAccessibilityLabel(NSLocalizedString("Back to Articles", comment: "Back button in Compact Mode"))
		backButton.translatesAutoresizingMaskIntoConstraints = false
	}

	func show(_ controller: NSViewController, showsBackButton: Bool, animated: Bool) {
		guard pane?.controller !== controller else {
			return
		}

		var interruptedOffset: CGFloat = 0
		if outgoingPane != nil, let activeHost = pane?.host {
			if let presentation = activeHost.layer?.presentation() {
				interruptedOffset = presentation.frame.minX - activeHost.frame.minX
			}
			finishTransition()
			activeHost.layer?.removeAnimation(forKey: Self.slideAnimationKey)
		}

		let width = view.safeAreaRect.width
		guard animated, let outgoing = pane, view.window?.isVisible == true, width > 0,
			  !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
			removePane()
			pane = installPane(controller, showsBackButton: showsBackButton)
			return
		}

		let forwardOffset = view.userInterfaceLayoutDirection == .rightToLeft ? -width : width
		let offset = showsBackButton ? forwardOffset : -forwardOffset
		let incoming = installPane(controller, showsBackButton: showsBackButton)
		pane = incoming
		outgoingPane = outgoing

		let transitionID = outgoing.id
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		CATransaction.setCompletionBlock { [weak self] in
			Task { @MainActor in
				guard let self, self.outgoingPane?.id == transitionID else {
					return
				}
				self.finishTransition()
			}
		}
		outgoing.horizontalPosition.constant = -offset
		view.layoutSubtreeIfNeeded()

		let slide = CABasicAnimation(keyPath: "transform.translation.x")
		slide.duration = 0.24
		slide.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
		slide.isAdditive = true
		slide.fromValue = offset + interruptedOffset
		slide.toValue = 0
		outgoing.host.layer?.add(slide, forKey: Self.slideAnimationKey)
		incoming.host.layer?.add(slide, forKey: Self.slideAnimationKey)
		CATransaction.commit()
	}

	func removePane() {
		finishTransition()
		if let pane {
			detach(pane)
			self.pane = nil
		}
	}

	private func installPane(_ controller: NSViewController, showsBackButton: Bool) -> Pane {
		addChild(controller)
		let host = showsBackButton ? articleHost : timelineHost
		let paneView = controller.view
		paneView.translatesAutoresizingMaskIntoConstraints = false
		host.addSubview(paneView)

		let safeArea = view.safeAreaLayoutGuide
		let topAnchor = showsBackButton ? backButton.bottomAnchor : safeArea.topAnchor
		var constraints = [
			paneView.topAnchor.constraint(equalTo: topAnchor, constant: showsBackButton ? 8 : 0),
			paneView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
			paneView.trailingAnchor.constraint(equalTo: host.trailingAnchor),
			paneView.bottomAnchor.constraint(equalTo: host.bottomAnchor)
		]
		if showsBackButton {
			host.addSubview(backButton)
			constraints.append(contentsOf: [
				backButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
				backButton.leadingAnchor.constraint(equalTo: paneView.leadingAnchor, constant: 12)
			])
		}
		NSLayoutConstraint.activate(constraints)
		let horizontalPosition = showsBackButton ? articlePosition : timelinePosition
		return Pane(controller: controller, host: host, showsBackButton: showsBackButton, horizontalPosition: horizontalPosition, constraints: constraints)
	}

	private func finishTransition() {
		guard let outgoingPane else {
			return
		}
		self.outgoingPane = nil
		detach(outgoingPane)
		view.window?.recalculateKeyViewLoop()
	}

	private func detach(_ pane: Pane) {
		pane.host.layer?.removeAnimation(forKey: Self.slideAnimationKey)
		pane.horizontalPosition.constant = 0
		NSLayoutConstraint.deactivate(pane.constraints)
		if pane.showsBackButton {
			backButton.removeFromSuperview()
		}
		pane.controller.view.removeFromSuperview()
		pane.controller.removeFromParent()
	}
}
