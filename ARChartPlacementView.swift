import SwiftUI
import RealityKit
import ARKit
import AVFoundation
import Combine
import UIKit

// =====================================================
// MARK: - Public SwiftUI Screen
// =====================================================

struct ARChartPlacementView: View {
    @State private var statusText = "Move slowly to detect a surface…"
    @State private var planeReady = false
    @State private var placed = false
    @State private var distanceM: Float = .nan
    @State private var showPermissionSheet = false
    @State private var cameraDenied = false

    // Blur amount
    @State private var blurAmount: CGFloat = 0

    // Navigation trigger
    @State private var goNext = false

    var body: some View {

        NavigationStack {   // 👈 ADDED

            ZStack {
                // AR view background
                if !cameraDenied {
                    ARContainer(
                        statusText: $statusText,
                        planeReady: $planeReady,
                        placed: $placed,
                        distanceM: $distanceM,
                        cameraDenied: $cameraDenied,
                        showPermissionSheet: $showPermissionSheet
                    )
                    .blur(radius: blurAmount)
                    .ignoresSafeArea()
                } else {
                    CameraDeniedView()
                }

                // HUD
                VStack(spacing: 10) {

                    // Top title
                    HStack {
                        Text("AR Chart Placement")
                            .font(.system(size: 22, weight: .semibold))
                            .padding(.leading)

                        Spacer()

                        Button("Next page") {
                            goNext = true          // 👈 GO TO NEXT VIEW
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .padding(8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.trailing)
                    }
                    .padding(.top, 8)

                    // Status text
                    Text(statusLine())
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.thinMaterial, in: Capsule())

                    Spacer()

                    // Plane guide while searching
                    if !placed {
                        PlaneGuide(ready: planeReady)
                            .frame(width: 190, height: 80)
                            .padding(.bottom, 10)
                    }

                    // Buttons
                    HStack {
                        Button {
                            NotificationCenter.default.post(name: .resetChartRequested, object: nil)
                        } label: {
                            Text("Reset")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(height: 48)
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!placed)

                        Button {
                            NotificationCenter.default.post(name: .placeChartRequested, object: nil)
                        } label: {
                            Text(placed ? "Reposition" : "Place Chart")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(height: 52)
                                .frame(maxWidth: .infinity)
                                .background(planeReady ? Color.blue : .gray)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!planeReady)
                    }
                    .padding(.horizontal, 20)

                    // Blur slider (only after placement)
                    if placed {
                        Slider(value: $blurAmount, in: 0...18)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                    }
                }
            }

            // 👇 NAVIGATION DESTINATION
            .navigationDestination(isPresented: $goNext) {
                VisionAnalysisMyopiaView()
            }

            .sheet(isPresented: $showPermissionSheet) { PermissionExplainerSheet() }
            .navigationBarBackButtonHidden(true)
            .animation(.easeInOut, value: planeReady)
            .animation(.easeInOut, value: placed)
        }
    }

    private func statusLine() -> String {
        if placed { return "Chart placed. Use the slider to blur." }
        if planeReady {
            if distanceM.isNaN { return "Surface detected. Aim and place." }
            let delta = abs(distanceM - 1.5)
            return delta < 0.15
                ? String(format: "Perfect distance (~%.2f m).", distanceM)
                : String(format: "Surface detected (%.2f m). Aim for ~1.50 m.", distanceM)
        }
        return statusText
    }
}

//
// MARK: - Notifications
//

extension Notification.Name {
    static let placeChartRequested = Notification.Name("placeChartRequested")
    static let resetChartRequested = Notification.Name("resetChartRequested")
}

//
// MARK: - HUD + PERMISSION VIEWS
//
private struct PlaneGuide: View {
    let ready: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Ellipse()
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6], dashPhase: phase))
                .foregroundColor(.blue.opacity(0.7))
                .background(Ellipse().fill(.blue.opacity(0.15)))
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 24
                    }
                }

            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 24))
                .padding(6)
                .background(.thinMaterial, in: Circle())
                .foregroundStyle(.white, .blue)
                .offset(x: 8, y: -8)
        }
    }
}

private struct PermissionExplainerSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundColor(.blue)

            Text("Camera Access Needed")
                .font(.title3.bold())

            Text("Enable Camera in Settings → EyeCheck to use AR.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, 18)
    }
}

private struct CameraDeniedView: View {
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Camera permission is required")
                .font(.headline)
            Text("Enable Camera in Settings to use AR features.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

//
// MARK: - AR UIViewRepresentable
//
private struct ARContainer: UIViewRepresentable {
    @Binding var statusText: String
    @Binding var planeReady: Bool
    @Binding var placed: Bool
    @Binding var distanceM: Float
    @Binding var cameraDenied: Bool
    @Binding var showPermissionSheet: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false
        arView.environment.sceneUnderstanding.options.insert(.occlusion)

        // Tap recognizer
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        // Notifications
        context.coordinator.setupNotifications(arView)

        // Camera permission
        context.coordinator.ensureCameraPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    context.coordinator.startSession(on: arView)
                } else {
                    cameraDenied = true
                    showPermissionSheet = true
                }
            }
        }

        arView.session.delegate = context.coordinator
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    //
    // MARK: - Coordinator
    //

    final class Coordinator: NSObject, ARSessionDelegate {
        private var parent: ARContainer
        private var chartAnchor: AnchorEntity?

        var placeCancellable: AnyCancellable?
        var resetCancellable: AnyCancellable?

        init(_ parent: ARContainer) {
            self.parent = parent
        }

        func setupNotifications(_ arView: ARView) {
            placeCancellable = NotificationCenter.default.publisher(for: .placeChartRequested)
                .sink { _ in self.placeChartCenter(in: arView) }

            resetCancellable = NotificationCenter.default.publisher(for: .resetChartRequested)
                .sink { _ in self.resetPlacement(in: arView) }
        }

        func ensureCameraPermission(completion: @escaping (Bool) -> Void) {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: completion(true)
            case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { completion($0) }
            default: completion(false)
            }
        }

        func startSession(on arView: ARView) {
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal, .vertical]
            config.environmentTexturing = .automatic
            arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
            parent.statusText = "Move slowly to detect a surface…"
        }

        //
        // CHART MODEL
        //
        
        func makeChartEntity() -> ModelEntity {
            let boardSize = SIMD2<Float>(0.50, 0.70)

            let plane = MeshResource.generatePlane(width: boardSize.x, height: boardSize.y)
            var material = UnlitMaterial()

            if let tex = try? TextureResource.load(named: "syntavlaAR") {   // 👈 TEXTURE NAME
                material.color = .init(texture: .init(tex))
            } else {
                print("⚠️ syntavlaAR not found in Assets")
                material.color = .init(tint: .white)
            }

            let chart = ModelEntity(mesh: plane, materials: [material])
            chart.position.z = 0.005

            // Wooden board behind
            let board = ModelEntity(
                mesh: .generateBox(size: [boardSize.x + 0.02, boardSize.y + 0.02, 0.012]),
                materials: [SimpleMaterial(color: .white, isMetallic: false)]
            )
            board.position.z = -0.006

            // Legs
            let legMat = SimpleMaterial(color: .brown, isMetallic: false)

            let leg1 = ModelEntity(mesh: .generateBox(size: [0.02, 0.50, 0.02]), materials: [legMat])
            let leg2 = leg1.clone(recursive: true)

            leg1.position = [-boardSize.x * 0.25, -boardSize.y * 0.35, -0.03]
            leg2.position = [ boardSize.x * 0.25, -boardSize.y * 0.35, -0.03]

            // Root
            let root = ModelEntity()
            root.addChild(board)
            root.addChild(chart)
            root.addChild(leg1)
            root.addChild(leg2)

            // Adjust height
            root.position.y = boardSize.y * 0.5

            return root
        }

        //
        // PLACE / RESET LOGIC
        //
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let pt = recognizer.location(in: arView)
            placeChart(from: pt, in: arView)
        }

        func placeChartCenter(in arView: ARView) {
            let c = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            placeChart(from: c, in: arView)
        }

        func placeChart(from point: CGPoint, in arView: ARView) {
            guard let frame = arView.session.currentFrame else { return }

            let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
            let chart = makeChartEntity()

            if let result = results.first {
                let anchor = AnchorEntity(raycastResult: result)
                anchor.addChild(chart)
                replaceAnchor(in: arView, with: anchor)
                parent.placed = true
                parent.statusText = "Placed on surface."
                return
            }

            // Fallback 1.5m forward
            let cam = frame.camera.transform
            let forward = -normalize(SIMD3<Float>(cam.columns.2.x, cam.columns.2.y, cam.columns.2.z))
            let pos = SIMD3<Float>(cam.columns.3.x, cam.columns.3.y, cam.columns.3.z) + forward * 1.5

            var m = matrix_identity_float4x4
            m.columns.3 = SIMD4<Float>(pos.x, pos.y, pos.z, 1)

            let anchor = AnchorEntity(world: m)
            anchor.addChild(chart)
            replaceAnchor(in: arView, with: anchor)
            parent.placed = true
            parent.statusText = "Placed 1.5m ahead."
        }

        func replaceAnchor(in arView: ARView, with new: AnchorEntity) {
            if let old = chartAnchor { arView.scene.anchors.remove(old) }
            arView.scene.anchors.append(new)
            chartAnchor = new
        }

        func resetPlacement(in arView: ARView) {
            if let old = chartAnchor {
                arView.scene.anchors.remove(old)
            }
            chartAnchor = nil
            parent.placed = false
            parent.statusText = "Placement reset. Aim and place again."
        }

        //
        // AR TRACKING
        //
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            if anchors.contains(where: { $0 is ARPlaneAnchor }) {
                parent.planeReady = true
                parent.statusText = "Surface detected. Aim the guide."
            }
        }
    }
}

//
// MARK: - Preview
//

#Preview {
    ARChartPlacementView()
}
