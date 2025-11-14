import SwiftUI

struct CompletionView: View {
    
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // MARK: - Title
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("🎉")
                        .font(.system(size: 34))
                    Text("You did it!")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text("Your eyes deserve the best care.")
                    .font(.system(size: 18))
                    .foregroundColor(.primary.opacity(0.7))
            }
            .padding(.top, 40)
            
            
            // MARK: - Image (static)
            Image("last_Image")        // 👈 your memoji image asset
                .resizable()
                .scaledToFit()
                .frame(width: 330)
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            
            
            // MARK: - Description
            VStack(spacing: 12) {
                Text("EyeCheck helps you understand your vision in a fun and interactive way.")
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal)
                
                Text("Keep exploring, and see the world in focus 👓")
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.horizontal)
            }
            
            
            // MARK: - Buttons
            VStack(spacing: 16) {
                
                // Retake Test
                NavigationLink(destination: StartView()) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retake Test")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                
                
                // Share button
                Button(action: {
                    showShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share EyeCheck with Friends")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Color.blue)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .sheet(isPresented: $showShareSheet) {
                    ActivityView(activityItems: ["Check your vision with EyeCheck!"])
                }
            }
            .padding(.top, 10)
            
            
            Spacer()
            
            
            // MARK: Footer
            Text("EyeCheck inspired by AR.\nBuilt for everyone.")
                .font(.system(size: 14))
                .foregroundColor(.primary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // MARK: - Static Gradient Background (NO animation)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.93, green: 0.97, blue: 1.0),
                    Color(red: 0.80, green: 0.90, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        
        .navigationBarBackButtonHidden(true)
        .navigationTitle("EyeCheck")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Share Sheet Helper
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


// MARK: - Preview
#Preview {
    NavigationStack {
        CompletionView()
    }
}
