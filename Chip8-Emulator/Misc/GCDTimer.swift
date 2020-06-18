//
//  GCDTimer.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 17.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation

class GCDTimer {

	private let timeInterval: DispatchTimeInterval

	private let queue: DispatchQueue

	private(set) var isPaused = false

	private let timer: DispatchSourceTimer

	private init(queue: DispatchQueue, timeInterval: DispatchTimeInterval, handler: @escaping () -> Void) {
		self.queue = queue
		self.timeInterval = timeInterval
		self.timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
		self.timer.setEventHandler(handler: handler)
	}

	deinit {
		self.cancel()
	}

	static func scheduledTimer(queue: DispatchQueue,
							   timeInterval: DispatchTimeInterval,
							   handler: @escaping () -> Void) -> GCDTimer {
		let timer = GCDTimer(queue: queue, timeInterval: timeInterval, handler: handler)
		timer.start()
		return timer
	}

	func cancel() {
		guard !timer.isCancelled else {
			return
		}

		timer.cancel()
	}

	func pause() {
		guard !isPaused else {
			return
		}

		timer.suspend()
		isPaused = true
	}

	func resume() {
		guard isPaused else {
			return
		}

		timer.resume()
		isPaused = false
	}
}

private extension GCDTimer {

	func start() {
		timer.schedule(deadline: .now(), repeating: timeInterval, leeway: .never)
		timer.activate()
	}
}
