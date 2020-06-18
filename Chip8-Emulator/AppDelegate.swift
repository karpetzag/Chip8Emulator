//
//  AppDelegate.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var window: NSWindow!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 500),
						  styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
						  backing: .buffered, defer: false)
		window.center()
		window.setFrameAutosaveName("Main Window")

		let contentView = EmulatorView()
		let viewModel = EmulatorViewModel(emulationController: EmulationController())
		window.contentView = NSHostingView(rootView: contentView.environmentObject(viewModel))
		window.makeKeyAndOrderFront(nil)
	}
}

