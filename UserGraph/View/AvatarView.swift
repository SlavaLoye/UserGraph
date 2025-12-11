//
//  AvatarView.swift
//  UserGraph
//
//  Created by Viacheslav Loie on 11.12.2025.
//

import SwiftUI

struct AvatarView: View {
    let url: URL?

    var body: some View {
        ZStack {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.avatarStroke, lineWidth: 1))
        .background(
            Circle().fill(Color(.secondarySystemBackground))
        )
    }

    private var placeholder: some View {
        ZStack {
            Color.clear
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .padding(8)
        }
    }
}
