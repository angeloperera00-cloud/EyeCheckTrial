import SwiftUI

struct ConsentSetupView: View {
    // MARK: Palette
    private let brand  = Color(red: 0.00, green: 0.34, blue: 0.87)
    private let eyeBG  = Color(red: 0.93, green: 0.96, blue: 1.00)
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // MARK: Animated Gradient Background (replaces the old static gradient)
            LinearGradient(
                gradient: Gradient(colors: [
                    animateGradient ? Color(red: 0.85, green: 0.95, blue: 1.0)
                                    : Color(red: 0.93, green: 0.97, blue: 1.0),
                    animateGradient ? Color(red: 0.75, green: 0.88, blue: 1.0)
                                    : Color(red: 0.80, green: 0.90, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            VStack(spacing: 14) {
                
                // MARK: Header – centered title only
                Text("Consent & Setup")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top, 12)
                
                // MARK: Consent text
                Text("By using this app, you understand that the results provided are for informational purposes only and should not be considered a substitute for professional eye exams.")
                    .font(.system(size: 15))
                    .foregroundColor(Color(UIColor.darkGray))
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .frame(width: 330, alignment: .leading)
                    .padding(.top, 8)
                
                Spacer(minLength: 0)
                
                // MARK: Main card
                VStack(spacing: 18) {
                    // Eye icon on soft circle
                    ZStack {
                        Circle()
                            .fill(eyeBG)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "eye")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(brand)
                        
                        
                            .symbolRenderingMode(.monochrome)
                    }
                    .padding(.top, 4)
                    
                    // Title + description
                    VStack(spacing: 10) {
                        Text("Ensure a suitable environment")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                        
                        Text("Make sure you are in a well lit area with enough space to use AR wherever you are standing.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 320)
                    }
                    .padding(.horizontal, 24)
                    
                    // ✅ Fixed: Use only NavigationLink (no Button)
                    NavigationLink(destination: ARChartPlacementView()) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
                    .padding(.bottom, 2)
                    
                }
                .padding(.vertical, 28)
                .frame(maxWidth: 350)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
                
                Spacer(minLength: 20)
                
                // MARK: Footer
                Text("Educational use only")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 18)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Consent Setup") {
    // ✅ Safe preview (uses placeholder, not AR)
    NavigationStack {
        ConsentSetupView()
            .navigationDestination(for: String.self) { _ in
                Text("ARChartPlacementView placeholder")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(white: 0.95))
            }
    }
}
