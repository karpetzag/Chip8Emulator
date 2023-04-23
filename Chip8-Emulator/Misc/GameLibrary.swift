//
//  GameLibrary.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import Foundation

struct Game: Codable, Identifiable, Hashable {

	let name: String
	let filename: String

	var id: String {
		return filename
	}
}

class GameLibrary {

	static let games: [Game] = {
		let path = Bundle.main.path(forResource: "roms", ofType: "json")!
		let data = FileManager.default.contents(atPath: path)!
		let games = try? JSONDecoder().decode([Game].self, from: data)
		return games ?? []
	}()

	static func loadGameRom(game: Game) -> Data {
		let path = Bundle.main.path(forResource: game.filename, ofType: nil)!
		let data = FileManager.default.contents(atPath: path)!
		return data
	}
}
