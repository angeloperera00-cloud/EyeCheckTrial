import SwiftUI

struct StartView: View {
    @State private var animateGradient = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated Gradient Background
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
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo + Title
                    VStack(spacing: 10) {
                        Image(systemName: "eyeglasses")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 40)
                            .foregroundStyle(.blue)
                            .shadow(color: .blue.opacity(0.2), radius: 4, y: 3)
                        
                        Text("EyeCheck")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.9))
                        
                        Text("Understand your vision in minutes")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Buttons
                    VStack(spacing: 20) {
                        NavigationLink(destination: ConsentSetupView()) {
                            Label("Start Visual Test", systemImage: "eye")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 5)
                        }
                        .padding(.horizontal, 50)
                        
                        NavigationLink(destination: ColorPerceptionView()) {
                            Label("Start Color Perception Test", systemImage: "circle.lefthalf.filled")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 5)
                        }
                        .padding(.horizontal, 50)
                    }
                    
                    /// if you added the UIViewControllerRepresentable named `GlassesView`
                    NavigationLink(destination: ARGlassesPlacementView().ignoresSafeArea()) {
                        Text("Learn how EyeCheck works 🔍")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(.top, 10)
                    }

                    
                    Spacer()
                    
                    // Footer
                    Text("Educational use only")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 25)
                }
                .multilineTextAlignment(.center)
            }
        }
    }
}

// Placeholder screens
struct VisualTestView: View {
    var body: some View {
        Text("Visual Test Coming Soon")
            .font(.title2.bold())
            .padding()
    }
}

struct ColorPerceptionView: View {
    var body: some View {
        Text("Color Perception Test Coming Soon")
            .font(.title2.bold())
            .padding()
    }
}

struct LearnMoreView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("How EyeCheck Works")
                    .font(.largeTitle.bold())
                    .padding(.top)
                
                Text("""
EyeCheck uses Augmented Reality (AR) and AI to help you understand your vision.

1️⃣ **Visual Test** analyzes your distance and clarity perception.  

2️⃣ **Color Perception Test** checks your color differentiation ability.  

3️⃣ **AI Insights** gives you an overview of your results in seconds.

Remember: EyeCheck is for educational use only and not a medical diagnostic tool.
""")
                .font(.body)
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    StartView()
}

