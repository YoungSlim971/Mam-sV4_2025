
import SwiftUI

struct SunsetImageWidgetView: View {
    @State private var currentImageName: String = "sunset1"
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(currentImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 350, height: 160)
                .clipped()
                .cornerRadius(12)
                .shadow(radius: 4)
                .transition(.opacity)
                .id(currentImageName)
                .animation(.easeInOut(duration: 0.5), value: currentImageName)

            Button(action: refreshImage) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding(10)
        }
        .frame(width: 350, height: 160)
        .onAppear {
            refreshImage()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func refreshImage() {
        let randomIndex = Int.random(in: 1...37)
        currentImageName = "sunset\(randomIndex)"
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            refreshImage()
        }
    }
}

#Preview {
    SunsetImageWidgetView()
}
