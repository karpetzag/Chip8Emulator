//
//  Decoder.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation

extension UInt16
{
    var hex: String {
        return String(format:"%04X", self)
    }
}

extension UInt8
{
    var hex: String {
        return String(format:"%02X", self)
    }
}

class Decoder {
    
    static func decodeRom(_ rom: Data) -> String {
		var result = ""
        for val in stride(from: 0, to: rom.count - 1, by: 2) {
            let rawCode: RawOpCode = (UInt16(rom[val]) << 8) | (UInt16(rom[val + 1]))
            let decoded = decode(rawOpCode: rawCode)
            let address = UInt16(val + Int(Chip8Emulator.Configuration.appStartAddress))
			result += "Addr \(address.hex) | OpCode \(rawCode.hex) | \(String(reflecting: decoded))"
			if val != rom.count - 2 {
				result += "\n"
			}
        }
		return result
    }
    
    static func decode(rawOpCode: RawOpCode) -> OpCode {
        let address = MemoryAddress(rawOpCode & 0x0FFF)
        
        let value = UInt8(rawOpCode & 0x00FF)
        let xRegister = Int((rawOpCode & 0x0F00) >> 8)
        let yRegister = Int((rawOpCode & 0x00F0) >> 4)
        
        let xIndex = Int(xRegister)
        let yIndex = Int(yRegister)
        
        let nibble = rawOpCode & 0x000F
        
        switch rawOpCode & 0xF000 {
        case 0x0000:
			switch value {
			case 0xE0: return .clearScreen
			case 0xEE: return .return
			default: return .unknown
			}
        case 0x1000: return .goto(address)
        case 0x2000: return .call(address)
        case 0x3000: return .skipNextIfVxEqualConstant(vxIndex: xIndex, value)
        case 0x4000: return .skipNextIfVxNotEqualConstant(vxIndex: xIndex, value)
        case 0x5000: return .skipNextIfVxEqualVy(vxIndex: xIndex, vyIndex: yIndex)
        case 0x6000: return .setValue(vxIndex: xIndex, value: value)
        case 0x7000: return .addValueToVx(vxIndex: xIndex, value: value)
        case 0x8000:
            switch nibble {
            case 0: return .setVxToVy(vxIndex: xIndex, vyIndex: yIndex)
            case 1: return .setVxToVxOrVy(vxIndex: xIndex, vyIndex: yIndex)
            case 2: return .setVxToVxAndVy(vxIndex: xIndex, vyIndex: yIndex)
            case 3: return .setVxToVxXorVy(vxIndex: xIndex, vyIndex: yIndex)
            case 4: return .addVyToVx(vxIndex: xIndex, vyIndex: yIndex)
            case 5: return .subVyFromVx(vxIndex: xIndex, vyIndex: yIndex)
			case 6: return .shiftRight(vxIndex: xIndex)
			case 7: return .subtract(vxIndex: xIndex, vyIndex: yIndex)
			case 0xE: return .shiftLeft(vxIndex: xIndex)
            default: return .unknown
            }
        case 0x9000: return .skipNextIfVxNotEqualVy(vxIndex: xIndex, vyIndex: yIndex)
        case 0xA000: return .setItoAddress(address: address)
        case 0xB000: return .relativeJump(address: address)
        case 0xC000: return .setVxToRandAndNN(vxIndex: xIndex, constant: value)
        case 0xD000: return .draw(vxIndex: xIndex, vyIndex: yIndex, height: Int(nibble))
        case 0xE000:
            switch value {
            case 0xA1: return .skipNextIfKeyIsNotPressed(vxIndex: xIndex)
			case 0x9E: return .skipNextIfKeyIsPressed(vxIndex: xIndex)
            default: return .unknown
            }
        case 0xF000:
            switch value {
            case 0x15: return .setDelayTimer(vxIndex: xIndex)
            case 0x07: return .getDelayTimerValue(vxIndex: xIndex)
            case 0x18: return .setSoundTimer(vxIndex: xIndex)
            case 0x33: return .setBCD(vxIndex: xIndex)
            case 0x65: return .load(vxIndex: xIndex)
			case 0x55: return .store(vxIndex: xIndex)
            case 0x29: return .loadFont(vxIndex: xIndex)
			case 0x1E: return .addVxToI(vxIndex: xIndex)
			case 0x0A: return .waitKey(vxIndex: xIndex)
            default: return .unknown
            }
        default: return .unknown
        }
    }
}

enum OpCode: CustomDebugStringConvertible
{
	var debugDescription: String {
		switch self {
		case .call(let address): return "Call address \(address.hex)"
		case .clearScreen: return "Clear Screen"
		case .goto(let address): return "Goto address \(address.hex)"
		case .return: return "Return"
		case .setValue(let vxIndex, let value): return "Set V[\(vxIndex)] = \(value.hex)"
		case .addValueToVx(let vxIndex, let value): return "Add \(value.hex) to V[\(vxIndex)] "
		case .setVxToVy(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] to V[\(vyIndex)] "
		case .skipNextIfVxEqualConstant(let vxIndex, let value): return "Skip next if V[\(vxIndex)] == \(value.hex)"
		case .skipNextIfVxNotEqualConstant(let vxIndex, let value): return "Skip next if V[\(vxIndex)] != \(value.hex)"
		case .skipNextIfVxEqualVy(let vxIndex, let vyIndex): return "Skip next if V[\(vxIndex)] == V[\(vyIndex)]"
		case .setVxToVxOrVy(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] |= V[\(vyIndex)]"
		case .setVxToVxAndVy(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] &= V[\(vyIndex)]"
		case .setVxToVxXorVy(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] ^= V[\(vyIndex)]"
		case .addVyToVx(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] += V[\(vyIndex)]"
		case .subVyFromVx(let vxIndex, let vyIndex): return "Set V[\(vxIndex)] -= V[\(vyIndex)]"
		case .skipNextIfVxNotEqualVy(let vxIndex, let vyIndex): return "Skip next if V[\(vxIndex)] != V[\(vyIndex)]"
		case .setItoAddress(let address): return "Set I to adress \(address.hex)"
		case .draw(let vxIndex, let vyIndex, let height): return "Draw x = \(vxIndex) y = \(vyIndex), height \(height)"
		case .setDelayTimer(let vxIndex): return "Set Delay V[\(vxIndex)] "
		case .getDelayTimerValue(let vxIndex): return "Get Delay V[\(vxIndex)] "
		case .setVxToRandAndNN(let vxIndex, let constant): return "Set V[\(vxIndex)] = random() & \(constant.hex)"
		case .skipNextIfKeyIsNotPressed(let vxIndex): return "Skip next if key[Vx[\(vxIndex)]] isn't pressed"
		case .setSoundTimer(let vxIndex): return "Set sound timer Vx[\(vxIndex)]"
		case .setBCD(let vxIndex): return "Set BCD Vx[\(vxIndex)]"
		case .load(let vxIndex): return "Load data from I to V[0] - Vx[\(vxIndex)]"
		case .store(let vxIndex): return "Store data from V[0] - Vx[\(vxIndex)] to I"
		case .loadFont(let vxIndex): return "Load font into I, Vx[\(vxIndex)]"
		case .relativeJump(let address): return "Jump to V[0] + \(address.hex)"
		case .unknown: return "Unknown Code"
		case .shiftRight(let vxIndex): return "V[\(vxIndex)] >>= 1"
		case .shiftLeft(let vxIndex): return "V[\(vxIndex)] <<= 1"
		case .subtract(let vxIndex, let vyIndex): return "Sets V[\(vxIndex)] to V[\(vyIndex)] minus V[\(vxIndex)]"
		case .addVxToI(let vxIndex): return "Adds V[\(vxIndex)] to I"
		case .skipNextIfKeyIsPressed(let vxIndex): return "Skip next if key[Vx[\(vxIndex)]] pressed"
		case .waitKey(let vxIndex): return "Wait key in Vx[\(vxIndex)]"
		}
	}

    case unknown
    case clearScreen //00E0
    case `return` // 00EE
    case goto(MemoryAddress) //1NNN
    case call(MemoryAddress) //2NNN
    case skipNextIfVxEqualConstant(vxIndex: RegisterIndex, Constant8bit) //3XNN
    case skipNextIfVxNotEqualConstant(vxIndex: RegisterIndex, Constant8bit) // 4XNN
    case skipNextIfVxEqualVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 5XY0
    case setValue(vxIndex: RegisterIndex, value: Constant8bit) //
    case addValueToVx(vxIndex: RegisterIndex, value: Constant8bit) // 7XNN
    case setVxToVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex)// 8XY0
    case setVxToVxOrVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex) //8XY1
    case setVxToVxAndVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 8XY2
    case setVxToVxXorVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 8XY3
    case addVyToVx(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 8XY4
    case subVyFromVx(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 8XY5
    case shiftRight(vxIndex: RegisterIndex) //8XY6
	case subtract(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 8XY7
	case shiftLeft(vxIndex: RegisterIndex) // 8XYE
    case skipNextIfVxNotEqualVy(vxIndex: RegisterIndex, vyIndex: RegisterIndex) // 9XY0
    case setItoAddress(address: MemoryAddress) // ANNN
    case relativeJump(address: MemoryAddress) // BNNN
    case setVxToRandAndNN(vxIndex: RegisterIndex, constant: Constant8bit) // CXNN
    case draw(vxIndex: RegisterIndex, vyIndex: RegisterIndex, height: Int) // DXYN
	case skipNextIfKeyIsPressed(vxIndex: RegisterIndex) // EX9E
    case skipNextIfKeyIsNotPressed(vxIndex: RegisterIndex) // EXA1
    case getDelayTimerValue(vxIndex: RegisterIndex) // FX07
    case waitKey(vxIndex: RegisterIndex) // FX0A
    case setDelayTimer(vxIndex: RegisterIndex)// FX15
    case setSoundTimer(vxIndex: RegisterIndex) // FX18
	case addVxToI(vxIndex: RegisterIndex) // FX1E
    case loadFont(vxIndex: RegisterIndex) // FX29
    case setBCD(vxIndex: RegisterIndex)  // FX33
	case store(vxIndex: RegisterIndex) // FX55
	case load(vxIndex: RegisterIndex) // FX65
}
