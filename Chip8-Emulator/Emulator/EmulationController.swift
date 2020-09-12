//
//  EmulationController.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation
import AppKit
import Combine

class EmulationController {

	enum State {
		case initial, running, paused
	}

	private enum TimerIntervals {
		static let loopTimer: TimeInterval = 1.0 / 500
		static let systemTimer: TimeInterval = 1.0 / 60.0
	}

	@Published private(set) var state = State.initial

	private(set) var screenUpdate = PassthroughSubject<[UInt8], Never>()

	private let queue = DispatchQueue(label: "com.chip8.emulator", qos: .userInteractive)

	private var rom: Data?
	private let emulator = Chip8Emulator()

	private lazy var loopTimer: GCDTimer = {
		let interval = DispatchTimeInterval.nanoseconds(TimerIntervals.loopTimer.toNanoseconds())
		let timer = GCDTimer.scheduledTimer(queue: self.queue,
											timeInterval: interval) { [weak self] in
												self?.onLoopTimerTick()
		}
		timer.pause()
		return timer
	}()

	private lazy var systemTimer: GCDTimer = {
		let interval = DispatchTimeInterval.nanoseconds(TimerIntervals.systemTimer.toNanoseconds())
		let timer = GCDTimer.scheduledTimer(queue: self.queue,
											timeInterval: interval) { [weak self] in
												self?.emulator.handleTimerTick()
		}
		timer.pause()
		return timer
	}()

	private lazy var displayLink = DisplayLink(onQueue: self.queue)
    private var needsRedraw = false

	deinit {
		systemTimer.cancel()
		loopTimer.cancel()
	}

    func handleInput(key: Key, isPressed: Bool) {
        queue.async { [weak self] in
			self?.emulator.handleInput(key: key, isPressed: isPressed)
        }
    }

	func restart() {
		guard let rom = self.rom else {
			return
		}
		
		restart(rom: rom)
	}

	func restart(rom: Data) {
		queue.async { [weak self] in
			guard let self = self else {
				return
			}

			self.rom = rom
			self.emulator.reset(rom: rom)

			switch self.state {
			case .initial:
				self.onStart()
				self.state = .running
			case .paused:
				self.resume()
			case .running:
				break
			}
		}
	}

	func pause() {
		queue.async { [weak self] in
			guard let self = self else {
				return
			}

			guard self.state == .running else {
				return
			}

			self.loopTimer.pause()
			self.systemTimer.pause()
			self.displayLink?.pause()
			self.state = .paused
		}
	}

	func resume() {
		queue.async { [weak self] in
			guard let self = self else {
				return
			}

			guard self.state == .paused else {
				return
			}

			self.loopTimer.resume()
			self.systemTimer.resume()
			self.displayLink?.resume()
			self.state = .running
		}
	}
}

private extension EmulationController
{
	func onStart() {
		systemTimer.resume()
		loopTimer.resume()

		displayLink?.callback = { [weak self] in
			self?.onRedraw()
		}

		displayLink?.start()

		let sound = NSSound(named: "Ping")
		emulator.soundHandler = {
			sound?.play()
		}
	}

    func onLoopTimerTick() {
        emulator.emulateCycle()
        if emulator.needsToRedraw {
            needsRedraw = true
        }
    }

    @objc
    func onRedraw() {
		guard needsRedraw else {
			return
		}

		needsRedraw = false
		screenUpdate.send(emulator.screen)
    }
}

extension TimeInterval
{
	func toNanoseconds() -> Int {
		Int(self * Double(NSEC_PER_SEC))
	}
}
