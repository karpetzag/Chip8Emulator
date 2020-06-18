//
//  EmulatorViewModel.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class EmulatorViewModel: ObservableObject {

	@Published private(set) var screenImage = NSImage()

	@Published private(set) var games = GameLibrary.games

	@Published var selectedGame: Game? {
		didSet {
			reload()
		}
	}

	@Published private(set) var state: EmulationController.State

	private var emulationController: EmulationController

	private var subscriptions = Set<AnyCancellable>()

	private var keyByButtonIndex =
	[
		0: Key.num1,
		1: Key.num2,
		2: Key.num3,
		3: Key.C,
		4: Key.num4,
		5: Key.num5,
		6: Key.num6,
		7: Key.D,
		8: Key.num7,
		9: Key.num8,
		10: Key.num9,
		11: Key.E,
		12: Key.A,
		13: Key.num0,
		14: Key.B,
		15: Key.F
	]

	init(emulationController: EmulationController) {
		self.emulationController = emulationController
		self.state = emulationController.state
		setup()
	}

	func onRestartButtonClick() {
		reload()
	}

	func onPauseButtonClick() {
		if emulationController.state == .running {
			emulationController.pause()
		} else {
			emulationController.resume()
		}
	}

	func onKeypadButtonStateChange(buttonIndex: Int, isPressed: Bool) {
		guard let key = keyByButtonIndex[buttonIndex] else {
			return
		}
		emulationController.handleInput(key: key, isPressed: isPressed)
	}
}

private extension EmulatorViewModel
{
	func setup() {
		emulationController.screenUpdate
			.map(makeScreenImage(screen:))
			.receive(on: RunLoop.main)
			.assign(to: \.screenImage, on: self)
			.store(in: &subscriptions)

		emulationController.$state
			.receive(on: RunLoop.main)
			.assign(to: \.state, on: self)
			.store(in: &subscriptions)
	}

	func reload() {
		if let game = selectedGame {
			emulationController.restart(rom: GameLibrary.loadGameRom(game: game))
		}
	}

	func makeScreenImage(screen: [UInt8]) -> NSImage {
		let pointSize = 4
		let width = Chip8Emulator.Configuration.screenWidth
		let height = Chip8Emulator.Configuration.screenHeight

		let size = NSSize(width: width * pointSize, height: height * pointSize)

		let image = NSImage(size: size)

		image.lockFocusFlipped(true)

		let context = NSGraphicsContext.current?.cgContext
		context?.setFillColor(.black)
		context?.fill(CGRect(origin: CGPoint(), size: size))

		var rects = [CGRect]()
        for x in 0..<width {
			for y in 0..<height {
                let index = y * width + x
                let val = screen[index]
                if val != 0 {
                    let rect = CGRect(x: x * pointSize, y: y * pointSize, width: pointSize , height: pointSize)
					rects.append(rect)
                }
            }
        }

		context?.setFillColor(NSColor.white.cgColor)
		context?.fill(rects)

		image.unlockFocus()

		return image
	}
}
