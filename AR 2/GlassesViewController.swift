import SwiftUI
import RealityKit
import ARKit
import simd

// MARK: - State
enum GlassesState: Equatable {
    case oscar
    case normal
}

// MARK: - Base VC
class ARViewControllerBase: UIViewController {
    let arView = ARView(frame: .zero)
    var sigma: Float = 0

    override func loadView() { view = arView }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: - Delegate
protocol GlassesViewControllerDelegate: AnyObject {
    func didWearGlasses(_ index: Int)
    func didPutGlassesDown()
}

// MARK: - Entity helper
private extension Entity {
    /// Walk up the parent chain to find a specific ancestor type.
    func findAncestor<T: Entity>(of type: T.Type) -> T? {
        var node: Entity? = self
        while let n = node {
            if let t = n as? T { return t }
            node = n.parent
        }
        return nil
    }
}

// MARK: - GlassesContainerEntity
final class GlassesContainerEntity: Entity {
    var animationDuration: Double = 0.35
    var distanceFromCamera: Float = 0.12

    let blur: Float
    private(set) var isPickedUp = false
    private let glasses: Entity
    private var originalParent: Entity?
    private var originalTransform: Transform?
    private var savedCollision: CollisionComponent?

    init(glasses source: Entity, blur: Float) {
        self.glasses = source.clone(recursive: true)
        self.blur = blur
        super.init()
        glasses.generateCollisionShapes(recursive: true)
        savedCollision = glasses.components[CollisionComponent.self]
        addChild(glasses)
    }

    @available(*, unavailable)
    required init() { fatalError("init() has not been implemented") }

    func pickUp(to cameraAnchor: AnchorEntity) {
        guard !isPickedUp, parent != nil else { return }
        isPickedUp = true

        originalParent = parent
        originalTransform = transform

        savedCollision = glasses.components[CollisionComponent.self]
        glasses.components.remove(CollisionComponent.self)

        removeFromParent(preservingWorldTransform: true)
        cameraAnchor.addChild(self, preservingWorldTransform: true)

        var target = Transform.identity
        target.translation = SIMD3(0, 0, -distanceFromCamera)
        target.rotation = simd_quatf(angle: .pi, axis: SIMD3(0, 1, 0))

        move(to: target, relativeTo: cameraAnchor, duration: animationDuration)
    }

    func putDown() {
        guard isPickedUp, let originalParent else { return }
        isPickedUp = false

        if let savedCollision { glasses.components.set(savedCollision) }

        removeFromParent(preservingWorldTransform: true)
        originalParent.addChild(self, preservingWorldTransform: true)

        if let originalTransform {
            move(to: originalTransform, relativeTo: originalParent, duration: animationDuration)
        }
        self.originalParent = nil
    }
}

// MARK: - GlassesViewController
final class GlassesViewController: ARViewControllerBase {

    var state: GlassesState = .normal {
        didSet {
            guard state != oldValue else { return }
            switch state {
            case .oscar:
                currentGlasses?.putDown()
                sigma = 0
            case .normal:
                sigma = noGlassesBlur
            }
        }
    }
    weak var delegate: GlassesViewControllerDelegate?

    private var cameraAnchor: AnchorEntity!
    private var tableAnchor: AnchorEntity!
    private var glassesContainers: [GlassesContainerEntity] = []
    private var currentGlasses: GlassesContainerEntity? {
        glassesContainers.first { $0.isPickedUp }
    }

    private var noGlassesBlur: Float { state == .oscar ? 0 : 20 }
    private let distanceBetweenGlasses: Float = 0.25
    private let glassesBlur: [Float] = [12, 6, 0, 6]

    override func viewDidLoad() {
        super.viewDidLoad()
        initAnchors()
        sigma = noGlassesBlur

        let base = loadGlassesEntity() ?? makePlaceholderGlasses()
        addGlasses(from: base)

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        arView.addGestureRecognizer(tapGR)
    }

    private func initAnchors() {
        tableAnchor = AnchorEntity(plane: .horizontal)
        arView.scene.addAnchor(tableAnchor)
        cameraAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(cameraAnchor)
    }

    private func addGlasses(from base: Entity) {
        for (i, blur) in glassesBlur.enumerated() {
            let container = GlassesContainerEntity(glasses: base, blur: blur)
            glassesContainers.append(container)
            tableAnchor.addChild(container)
            container.position.x = Float(i) * distanceBetweenGlasses
        }
    }

    private func updateBlur() {
        sigma = noGlassesBlur
        if let held = currentGlasses { sigma = held.blur }
    }

    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        let pt = sender.location(in: arView)

        if let hit = arView.entity(at: pt),
           let container = hit.findAncestor(of: GlassesContainerEntity.self) {
            if container.isPickedUp { return }

            for other in glassesContainers where other.isPickedUp && other !== container {
                other.putDown()
            }

            updateBlur()

            if let idx = glassesContainers.firstIndex(where: { $0 === container }) {
                container.pickUp(to: cameraAnchor)
                delegate?.didWearGlasses(idx)
            }
        } else {
            currentGlasses?.putDown()
            updateBlur()
            delegate?.didPutGlassesDown()
        }
    }

    private func loadGlassesEntity() -> Entity? {
        if let e1 = try? Entity.load(named: "Glasses") { return e1 }
        if let e2 = try? Entity.load(named: "glasses") { return e2 }
        return nil
    }

    private func makePlaceholderGlasses() -> Entity {
        let frame = MeshResource.generateBox(size: [0.14, 0.04, 0.02], cornerRadius: 0.01)
        let lensL = MeshResource.generateBox(size: [0.06, 0.04, 0.01], cornerRadius: 0.008)
        let lensR = MeshResource.generateBox(size: [0.06, 0.04, 0.01], cornerRadius: 0.008)
        let mat = SimpleMaterial()
        let root = Entity()

        let frameE = ModelEntity(mesh: frame, materials: [mat])
        let left = ModelEntity(mesh: lensL, materials: [mat])
        let right = ModelEntity(mesh: lensR, materials: [mat])

        frameE.position = [0, 0, 0]
        left.position  = [-0.04, 0, 0]
        right.position = [ 0.04, 0, 0]

        root.addChild(frameE)
        root.addChild(left)
        root.addChild(right)
        root.generateCollisionShapes(recursive: true)
        return root
    }
}

// MARK: - SwiftUI Bridge
enum GlassesUIState: Equatable {
    case oscar
    case jessica(Int?)
}

struct GlassesViewControllerBridge: UIViewControllerRepresentable {
    typealias UIViewControllerType = GlassesViewController
    @Binding var state: GlassesUIState

    func makeUIViewController(context: Context) -> GlassesViewController {
        let vc = GlassesViewController()
        vc.state = mapToVC(state)
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: GlassesViewController, context: Context) {
        vc.state = mapToVC(state)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private func mapToVC(_ s: GlassesUIState) -> GlassesState {
        switch s {
        case .oscar: return .oscar
        case .jessica: return .normal
        }
    }

    final class Coordinator: NSObject, GlassesViewControllerDelegate {
        var parent: GlassesViewControllerBridge
        init(parent: GlassesViewControllerBridge) { self.parent = parent }

        func didWearGlasses(_ index: Int) { parent.state = .jessica(index) }
        func didPutGlassesDown() { parent.state = .oscar }
    }
}

// MARK: - Unified AR Page
struct ARGlassesPlacementView: View {
    @State private var state: GlassesUIState = .oscar
    @State private var goNext = false     // 👈 Navigation trigger

    var body: some View {
        ZStack {
            GlassesViewControllerBridge(state: $state)
                .ignoresSafeArea()

            VStack {
                // Top title + Next page button
                HStack {
                    Text("AR Glasses Placement")
                        .font(.system(size: 22, weight: .semibold))
                        .padding(.leading)

                    Spacer()

                    Button(action: {
                        goNext = true            // 👈 GO TO VISION VIEW
                    }) {
                        Text("Next page")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .padding(.trailing)
                }
                .padding(.top, 8)

                Spacer()

                VStack(spacing: 16) {
                    Button("Place Glasses") {
                        state = .jessica(nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button("Reset") {
                        state = .oscar
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)
            }
        }
        // 👇 Uses the same NavigationStack started in ARChartPlacementView
        .navigationDestination(isPresented: $goNext) {
            CompletionView()
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
#Preview {
    ARGlassesPlacementView()
}
