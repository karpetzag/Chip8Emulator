//
//  Chip8Emulator.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation

typealias Register = UInt8
typealias MemoryAddress = UInt16
typealias Constant8bit = UInt8
typealias RegisterIndex = Int
typealias RawOpCode = UInt16
typealias RegisterSize = UInt16

enum Key: UInt8 {
    case num0 = 0x0
    case num1 = 0x1
    case num2 = 0x2
    case num3 = 0x3
    case num4 = 0x4
    case num5 = 0x5
    case num6 = 0x6
    case num7 = 0x7
    case num8 = 0x8
    case num9 = 0x9
    case A = 0xA
    case B = 0xB
    case C = 0xC
    case D = 0xD
    case E = 0xE
    case F = 0xF
}

class Chip8Emulator {

    enum Configuration {

        static let numberOfRegisters = 16

        static let appStartAddress: UInt16 = 0x200

        static let memorySize = 1024 * 4

        static let screenWidth = 64
        static let screenHeight = 32

        static let stackSize = 16

        static let numberOfKeys = 16

        static let fonts: [UInt8] = [
          0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
          0x20, 0x60, 0x20, 0x20, 0x70, // 1
          0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
          0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
          0x90, 0x90, 0xF0, 0x10, 0x10, // 4
          0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
          0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
          0xF0, 0x10, 0x20, 0x40, 0x40, // 7
          0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
          0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
          0xF0, 0x90, 0xF0, 0x90, 0x90, // A
          0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
          0xF0, 0x80, 0x80, 0x80, 0xF0, // C
          0xE0, 0x90, 0x90, 0x90, 0xE0, // D
          0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
          0xF0, 0x80, 0xF0, 0x80, 0x80  // F
        ]

    }

	var soundHandler: (() -> Void)?

    private(set) var V = [Register](repeating: 0, count: Configuration.numberOfRegisters)
    private(set) var I: MemoryAddress = 0x0000
    private(set) var memory = [UInt8](repeating: 0, count: Configuration.memorySize)

    private(set) var stack = [MemoryAddress](repeating: 0, count: Configuration.stackSize)
    private(set) var sp = 0

    private(set) var needsToRedraw = false
    private(set) var needsToPlaySound = false

    private(set) var screen = [UInt8](repeating: 0, count: Configuration.screenWidth * Configuration.screenHeight)

    private(set) var pc = Configuration.appStartAddress

    private var keypad = [Bool](repeating: false, count: Configuration.numberOfKeys)

    private var delayTimerValue = 0
    private var soundTimerValue = -1

	func reset(rom: Data) {
		reset()
		loadRom(rom)
	}

	func reset() {
		sp = 0
		stack = [MemoryAddress](repeating: 0, count: Configuration.stackSize)
		V = [Register](repeating: 0, count: Configuration.numberOfRegisters)
		I = 0x0000
		memory = [UInt8](repeating: 0, count: Configuration.memorySize)
		needsToPlaySound = false
		pc = Configuration.appStartAddress
		keypad = [Bool](repeating: false, count: Configuration.numberOfKeys)
		screen = [UInt8](repeating: 0, count: Configuration.screenWidth * Configuration.screenHeight)
		delayTimerValue = 0
		soundTimerValue = -1
	}

    func handleInput(key: Key, isPressed: Bool) {
        keypad[Int(key.rawValue)] = isPressed
    }

    func handleTimerTick() {
        if self.delayTimerValue > 0 {
            self.delayTimerValue -= 1
        }

        if soundTimerValue > 0 {
            soundTimerValue -= 1
        } else if soundTimerValue == 0 {
            soundTimerValue -= 1
			soundHandler?()
        }
    }

	func emulateCycle() {
		let rawOpCode = (UInt16(memory[Int(pc)]) << 8 | UInt16( memory[Int(pc) + 1]))
		let opCode = Decoder.decode(rawOpCode: rawOpCode)

        var shouldIncrementPC = true
		needsToRedraw = false

		switch opCode {
		case .unknown:
			fatalError("OpCode \(rawOpCode.hex) is not implemented")
		case .clearScreen:
			(0..<screen.count).forEach({ screen[$0] = 0 })
			needsToRedraw = true
		case .return:
			sp -= 1
			pc = stack[sp]
		case .goto(let address):
			pc = address
			shouldIncrementPC = false
		case .call(let address):
			stack[sp] = pc
			sp += 1
			pc = address
			shouldIncrementPC = false
		case .skipNextIfVxEqualConstant(let vxIndex, let value):
			if V[vxIndex] == value {
				pc += 2
			}
		case .skipNextIfVxNotEqualConstant(let vxIndex, let value):
			if V[vxIndex] != value {
				pc += 2
			}
		case .skipNextIfVxEqualVy(let vxIndex, let vyIndex):
			if V[vxIndex] == V[vyIndex] {
				pc += 2
			}
		case .setValue(let vxIndex, let value):
			V[vxIndex] = value
		case .addValueToVx(let vxIndex, let value):
			V[vxIndex] &+= value
		case .setVxToVy(let vxIndex, let vyIndex):
			V[vxIndex] = V[Int(vyIndex)]
		case .setVxToVxOrVy(let vxIndex, let vyIndex):
			V[vxIndex] = V[vxIndex] | V[vyIndex]
		case .setVxToVxAndVy(let vxIndex, let vyIndex):
			V[vxIndex] = V[vxIndex] & V[vyIndex]
		case .setVxToVxXorVy(let vxIndex, let vyIndex):
			V[vxIndex] = V[vxIndex] ^ V[vyIndex]
		case .addVyToVx(let vxIndex, let vyIndex):
			V[0xF] = (Int(V[vxIndex]) + Int(V[vyIndex])) > UInt8.max ? 1 : 0
			V[vxIndex] &+= V[vyIndex]
		case .subVyFromVx(let vxIndex, let vyIndex):
			V[0xF] = V[vxIndex] > V[vyIndex] ? 1 : 0
			V[vxIndex] = V[vxIndex] &- V[vyIndex]
		case .shiftRight(let vxIndex):
			let val = V[vxIndex] & 0x01
			V[0xF] = val
			V[vxIndex] >>= 1
		case .subtract(let vxIndex, let vyIndex):
			V[0xF] = V[vyIndex] < V[vxIndex] ? 0 : 1
			V[vxIndex] = V[vyIndex] &- V[vxIndex]
		case .shiftLeft(let vxIndex):
			let val = (V[vxIndex] >> 7) & 0x01
			V[0xF] = val
			V[vxIndex] <<= 1
		case .skipNextIfVxNotEqualVy(let vxIndex, let vyIndex):
			if V[vxIndex] != V[vyIndex] {
				pc += 2
			}
		case .setItoAddress(let address):
			I = address
		case .relativeJump(let address):
			pc = MemoryAddress(V[0]) + address
			shouldIncrementPC = false
		case .setVxToRandAndNN(let vxIndex, let value):
			let randomValue = UInt8.random(in: 0..<UInt8.max)
			V[vxIndex] = randomValue & value
		case .draw(let vxIndex, let vyIndex, let height):
			needsToRedraw = true

			let x = Int(V[vxIndex])
			let y = Int(V[vyIndex])

			V[0xF] = 0
			for yLine in 0..<height {
				let sprite = memory[Int(I) + yLine]
				for xLine in 0..<8 {
					let byte: UInt8 = 0x80
					guard (sprite & (byte >> xLine)) != 0 else {
						continue
					}

					let screenY = (y + yLine) % Configuration.screenHeight
					let screenX = (x + xLine) % Configuration.screenWidth
					let screenIndex = (screenY * Configuration.screenWidth) + screenX

					if screen[screenIndex] == 1 {
						V[0xF] = 1
					}
					screen[screenIndex] ^= 1
				}
			}
		case .skipNextIfKeyIsPressed(let vxIndex):
			  if keypad[Int(V[vxIndex])] {
				pc += 2
			}
		case .skipNextIfKeyIsNotPressed(let vxIndex):
			if !keypad[Int(V[vxIndex])] {
				pc += 2
			}
		case .getDelayTimerValue(let vxIndex):
			V[vxIndex] = UInt8(delayTimerValue)
		case .setDelayTimer(let vxIndex):
			delayTimerValue = Int(V[vxIndex])
		case .setSoundTimer(let vxIndex):
			soundTimerValue = Int(V[vxIndex])
		case .addVxToI(let vxIndex):
			V[0xF] = (I + UInt16(V[vxIndex])) > 0xFFF ? 1 : 0
			I &+= UInt16(V[vxIndex])
		case .loadFont(let vxIndex):
			let fontWidth: UInt8 = 5
			let val = V[vxIndex]
			I = UInt16(val * fontWidth)
		case .setBCD(let vxIndex):
			let value = V[Int(vxIndex)]
			memory[Int(I)] = value / 100
			memory[Int(I) + 1] = (value / 10) % 10
			memory[Int(I) + 2] = (value % 100) % 10
		case .store(let vxIndex):
			(0...vxIndex).enumerated().forEach { (index, register) in
				memory[Int(I) + index] = self.V[Int(register)]
			}
		case .load(let vxIndex):
			(0...vxIndex).enumerated().forEach { (index, register) in
				V[Int(register)] = memory[Int(I) + index]
			}
		case .waitKey(let vxIndex):
			if let index = keypad.firstIndex(where: {$0 == true}) {
				V[vxIndex] = UInt8(index)
			} else {
				return
			}
		}

		if shouldIncrementPC {
			pc += 2
		}
	}
}

private extension Chip8Emulator {

	func loadRom(_ rom: Data) {
		for (index, byte) in rom.enumerated() {
			memory[index + Int(Configuration.appStartAddress)] = byte
		}

		for (index, byte) in Configuration.fonts.enumerated() {
			memory[index] = byte
		}
	}
}
