import SwiftUI

// For your "Continue" callback
typealias NextAction = () -> Void

struct VisionAnalysisMyopiaView: View {
    @State private var goToGlasses = false   // ← controls navigation

    var body: some View {
        NavigationStack {
            TaskView(nextAction: {
                goToGlasses = true           // ← When Continue pressed → navigate
            })
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $goToGlasses) {
                ARGlassesPlacementView()     // ← Your AR screen
            }
        }
    }
}

//
// MARK: - Reusable Primary Button
//
struct ButtonBridge: View {
    var title: String = "Continue"
    var action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

//
// MARK: - Task Card Content
//
struct TaskView: View {
    var nextAction: NextAction?
    @State private var focusSlide: Double

    init(nextAction: NextAction? = nil, initialFocus: Double = 0) {
        self.nextAction = nextAction
        _focusSlide = State(initialValue: initialFocus)
    }

    private let target: Double = -8.36
    private let okRange: Double = 0.5

    private var completedTask: Bool {
        (target - okRange) < focusSlide && focusSlide < (target + okRange)
    }

    private var imageBlur: CGFloat {
        // Cap blur so the chart never disappears completely
        min(CGFloat(abs(target - focusSlide)), 8)
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack {

                    //  CARD
                    VStack(alignment: .leading, spacing: 20) {

                        Text("Vision Analysis Myopia")
                            .font(.system(.title, design: .default).weight(.semibold))

                        Text("Short sightedness, also called near sightedness and myopia, means the eye focuses the light in front of the retina. Distant objects appear blurry while close objects appear normal.")
                            .font(.body)

                        HStack(spacing: 16) {
                            // Eye chart image
                            Image("syntavla")
                                .resizable()
                                .scaledToFit()
                                .blur(radius: imageBlur)
                                .frame(width: 100, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(.quaternary, lineWidth: 1)
                                )

                            // Optics simulation
                            LightSimulationView(value: focusSlide / 10)
                                .frame(width: 220, height: 140)
                        }

                        Text("This can be corrected by adding a lens that adjusts light so the focus point moves back to the retina.")
                            .font(.body)

                        VStack(spacing: 8) {
                            Slider(value: $focusSlide, in: -10...10)
                            Text(String(format: "%.6f", focusSlide))
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        ButtonBridge {
                            nextAction?()          // ← triggers navigation
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color(.quaternaryLabel), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    .frame(maxWidth: 480)
                    .frame(minHeight: proxy.size.height * 0.9, alignment: .top)
                    // ---------------- END CARD ------------------

                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
    }
}

//
// MARK: - Lens view
//
struct LenseView: View {
    var value: Double = 0

    var body: some View {
        GeometryReader { gr in
            Path { path in
                let offset = -CGFloat(value) * gr.size.width / 2

                path.move(to: .zero)
                path.addCurve(
                    to: CGPoint(x: 0, y: gr.size.height),
                    control1: CGPoint(x: offset, y: gr.size.height/2),
                    control2: CGPoint(x: offset, y: gr.size.height/2)
                )

                path.addLine(to: CGPoint(x: gr.size.width, y: gr.size.height))

                path.addCurve(
                    to: CGPoint(x: gr.size.width, y: 0),
                    control1: CGPoint(x: gr.size.width - offset, y: gr.size.height/2),
                    control2: CGPoint(x: gr.size.width - offset, y: gr.size.height/2)
                )

                path.closeSubpath()
            }
            .fill(.blue)
        }
    }
}

//
// MARK: - Light Simulation View
//
struct LightSimulationView: View {
    var value: Double

    var body: some View {
        HStack(spacing: 12) {

            LenseView(value: value)
                .frame(width: 16, height: 140)

            Spacer(minLength: 8)

            Image("eye")
                .resizable()
                .scaledToFit()
                .frame(height: 140)
        }
        .overlay {
            GeometryReader { gr in
                Path { path in
                    let lenseGap: CGFloat = 12
                    let eyeX: CGFloat = 58
                    let eyeGap: CGFloat = -10 * CGFloat(value)
                    let focusX: CGFloat = min(gr.size.width - 10, 190 - CGFloat(value) * 80)

                    // TOP ray
                    path.move(to: CGPoint(x: -80, y: gr.size.height/2 - lenseGap))
                    path.addLine(to: CGPoint(x: 0, y: gr.size.height/2 - lenseGap))
                    path.addLine(to: CGPoint(x: eyeX, y: gr.size.height/2 - lenseGap - eyeGap))
                    path.addLine(to: CGPoint(x: focusX, y: gr.size.height/2))

                    // BOTTOM ray
                    path.move(to: CGPoint(x: -80, y: gr.size.height/2 + lenseGap))
                    path.addLine(to: CGPoint(x: 0, y: gr.size.height/2 + lenseGap))
                    path.addLine(to: CGPoint(x: eyeX, y: gr.size.height/2 + lenseGap + eyeGap))
                    path.addLine(to: CGPoint(x: focusX, y: gr.size.height/2))
                }
                .stroke(.yellow, lineWidth: 3)
            }
        }
    }
}

//
// MARK: - Previews
// 
#Preview("iPhone 17 Pro – Portrait") {
    VisionAnalysisMyopiaView()
}

#Preview("Completed State") {
    TaskView(nextAction: {}, initialFocus: -8.36)
        .padding(.horizontal, 16)
}
