import SwiftUI

struct RatingView: View {
    let rating: Double
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star))
                    .font(.system(size: size))
                    .foregroundStyle(.yellow)
            }
        }
    }

    private func starImageName(for star: Int) -> String {
        let value = Double(star)
        if rating >= value {
            return "star.fill"
        } else if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct RatingInputView: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: starImageName(for: star))
                    .font(.system(size: 28))
                    .foregroundStyle(.yellow)
                    .onTapGesture {
                        let value = Double(star)
                        if rating == value {
                            rating = value - 0.5
                        } else if rating == value - 0.5 {
                            rating = 0
                        } else {
                            rating = value
                        }
                    }
            }

            if rating > 0 {
                Button {
                    rating = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func starImageName(for star: Int) -> String {
        let value = Double(star)
        if rating >= value {
            return "star.fill"
        } else if rating >= value - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
