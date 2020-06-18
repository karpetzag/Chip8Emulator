//
//  EmulatorView.swift
//  Chip8-Emulator
//
//  Created by Карпец Андрей on 16.06.2020.
//  Copyright © 2020 AK. All rights reserved.
//

import SwiftUI

struct EmulatorView: View {

	@EnvironmentObject var viewModel: EmulatorViewModel

    var body: some View {
		HStack(alignment: .top, spacing: 16, content: {
			ZStack(alignment: .center, content: {
				Color(.lightGray).border(Color.gray, width: 1)
				Image(nsImage: viewModel.screenImage).resizable().aspectRatio(contentMode: ContentMode.fit)
			}).frame(alignment: .topLeading)

			VStack {
				Picker(selection: $viewModel.selectedGame, label: EmptyView()) {
					if viewModel.selectedGame == nil {
						Text("...").tag(nil as Game?)
					}
					ForEach(viewModel.games) {
						Text($0.name).tag($0 as Game?)
					}
				}

				HStack {
					Button(action: viewModel.onRestartButtonClick) {
						Text("Restart")
					}.disabled(viewModel.state == .initial)

					Button(action: viewModel.onPauseButtonClick) {
						Text(viewModel.state == .paused ? "Resume" : "Pause")
					}.disabled(viewModel.state == .initial)
				}.padding()

				Keypad(action: self.viewModel.onKeypadButtonStateChange(buttonIndex:isPressed:))

			}.frame(minWidth: 200, maxWidth: 200)
		}).padding()
	}
}

struct Keypad: View {

	private let action: (Int, Bool) -> Void

	private let width = 4
	private let height = 4

	init(action: @escaping (Int, Bool) -> Void) {
		self.action = action
	}

	var body: some View {
		ForEach(0..<width) { rowIndex in
			HStack {
				ForEach(0..<self.height) { columnIndex in
					KeypadButton(value: self.keyValue(row: rowIndex, column: columnIndex)) { isPressed in
						self.action(rowIndex * self.height + columnIndex, isPressed)
					}
				}
			}
		}
	}


	func keyValue(row: Int, column: Int) -> String {
		let index = row * self.height + column
		switch index {
		case 0: return "1"
		case 1: return "2"
		case 2: return "3"
		case 3: return "C"

		case 4: return "4"
		case 5: return "5"
		case 6: return "6"
		case 7: return "D"

		case 8: return "7"
		case 9: return "8"
		case 10: return "9"
		case 11: return "E"

		case 12: return "A"
		case 13: return "0"
		case 14: return "B"
		case 15: return "F"

		default:
			return "X"
		}
	}
}

struct KeypadButton: View {

	@State var isPressed = false

	private let value: String
	private let action: (Bool) -> Void

	init(value: String, action: @escaping (Bool) -> Void) {
		self.value = value
		self.action = action
	}

	var body: some View {
		Rectangle()
			.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local).onChanged({ _ in
						guard !self.isPressed else {
							return
						}
						self.isPressed = true
						self.action(true)
					}).onEnded({ _ in
						self.isPressed = false
						self.action(false)
			}))
			.foregroundColor(isPressed ? Color(white: 0.9) : Color.white)
			.frame(width: 40, height: 40)
			.overlay(Text(value).allowsHitTesting(false)
			.font(.subheadline))

	}
}
