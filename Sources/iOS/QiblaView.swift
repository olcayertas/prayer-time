import SwiftUI
import CoreLocation
import UIKit

/// iOS Qibla finder: a live compass whose arrow points toward the Kaaba. The bearing math is in
/// `Qibla` (Core); `QiblaController` supplies the device coordinate + heading. iOS-only — it needs
/// a magnetometer, so it lives in `Sources/iOS` and the Mac app never builds it.
struct QiblaView: View {
    @ObservedObject var store: PrayerStore
    @StateObject private var qibla = QiblaController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    content
                }
                .padding(24)
                // Fill the viewport so the content centers vertically; still scrolls if it
                // outgrows the screen (e.g. large Dynamic Type).
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
        }
        .navigationTitle("Qibla")
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // "Activate on first open": opening the tab asks for location the first time, then the
            // compass just works. requestAuthorization is a no-op once the choice is made.
            if qibla.authorizationStatus == .notDetermined { qibla.requestAuthorization() }
            qibla.start()
        }
        .onDisappear { qibla.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { qibla.start() } else { qibla.stop() }
        }
    }

    @ViewBuilder private var content: some View {
        switch qibla.authorizationStatus {
        case .notDetermined:
            requestingAccess
        case .denied, .restricted:
            status("location.slash.fill", "Location access needed",
                   "Allow location for Prayer Times in Settings to find the Qibla.") {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        default:
            if !CLLocationManager.headingAvailable() {
                status("iphone.slash", "No compass",
                       "This device doesn't have a compass, so the Qibla direction can't be shown here.")
            } else if qibla.coordinate == nil {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Finding your location…").foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                liveCompass
            }
        }
    }

    // MARK: Live compass

    private var liveCompass: some View {
        VStack(spacing: 20) {
            CompassDial(
                heading: qibla.headingDegrees ?? 0,
                qiblaBearing: qibla.qiblaBearing ?? 0,
                isAligned: qibla.isAligned
            )
            .frame(width: 300, height: 300)
            .padding(.top, 8)

            if qibla.isAligned {
                Label("Facing the Qibla", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
            } else if let bearing = qibla.qiblaBearing {
                Text("\(Int(bearing.rounded()))° from North")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .monospacedDigit()
            }

            Text(store.locationName)
                .font(.callout)
                .foregroundStyle(.secondary)

            if qibla.isCalibrating {
                hint("figure.walk.motion", "Move your phone in a figure 8 to calibrate the compass.")
            } else if !qibla.usingTrueNorth {
                hint("location.circle", "Improving accuracy…")
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: qibla.isAligned) { wasAligned, aligned in
            if aligned && !wasAligned {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private var requestingAccess: some View {
        status("location.north.circle.fill", "Find the Qibla",
               "Prayer Times uses your location to point the compass toward the Kaaba in Mecca.") {
            Button("Allow Location") { qibla.requestAuthorization() }
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: Building blocks

    private func hint(_ symbol: String, _ text: LocalizedStringKey) -> some View {
        Label(text, systemImage: symbol)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    /// A centered icon + title + message, with an optional action button — used for every
    /// non-live state (permission, no-compass).
    private func status(
        _ symbol: String,
        _ title: LocalizedStringKey,
        _ message: LocalizedStringKey,
        @ViewBuilder action: () -> some View = { EmptyView() }
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)
            Text(title).font(.title2.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            action()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
}

/// The compass graphic: a rotating rose (so North tracks true north) with a fixed top reference
/// and a bold arrow toward the qibla. Animates on a continuous, accumulated heading so the needle
/// always takes the shortest path across the 0°/360° seam instead of spinning all the way around.
private struct CompassDial: View {
    let heading: Double
    let qiblaBearing: Double
    let isAligned: Bool

    /// Continuous (un-normalized) heading the view animates toward — see `update(to:)`.
    @State private var displayHeading: Double = 0

    private let radius: CGFloat = 150

    var body: some View {
        ZStack {
            rose
            kaabaMarker
            qiblaArrow
            topReference
            centerLabel
        }
        .frame(width: radius * 2, height: radius * 2)
        .animation(.easeOut(duration: 0.12), value: displayHeading)
        .onAppear { displayHeading = heading }
        .onChange(of: heading) { _, new in update(to: new) }
        .accessibilityElement()
        .accessibilityLabel(Text("Qibla compass"))
        .accessibilityValue(Text("\(Int(qiblaBearing.rounded())) degrees from north"))
    }

    /// The qibla's angle on screen, measured clockwise from the top (= the direction the phone
    /// faces). When this is 0 the phone points at the qibla.
    private var qiblaScreenAngle: Double { qiblaBearing - displayHeading }

    private var tint: Color { isAligned ? .green : Color.accentColor }

    private var rose: some View {
        ZStack {
            Circle().fill(Color.cardBackground)
            Circle().strokeBorder(Color.secondary.opacity(0.25), lineWidth: 2)
            ForEach(0..<72, id: \.self) { i in
                let major = i % 9 == 0
                Rectangle()
                    .fill(Color.secondary.opacity(major ? 0.55 : 0.22))
                    .frame(width: major ? 2 : 1, height: major ? 12 : 6)
                    .offset(y: -(radius - 10))
                    .rotationEffect(.degrees(Double(i) / 72 * 360))
            }
            ForEach(Cardinal.all) { c in
                Text(c.label)
                    .font(.headline.weight(c.label == "N" ? .bold : .regular))
                    .foregroundStyle(c.label == "N" ? .red : .secondary)
                    .offset(y: -(radius - 32))
                    .rotationEffect(.degrees(c.angle))
            }
        }
        .rotationEffect(.degrees(-displayHeading)) // rotate the whole card so N tracks true north
    }

    /// A small Kaaba glyph sitting on the rim in the qibla's direction.
    private var kaabaMarker: some View {
        Image(systemName: "cube.fill")
            .font(.system(size: 20))
            .foregroundStyle(tint)
            .padding(6)
            .background(Color.cardBackground, in: Circle())
            .offset(y: -(radius - 4))
            .rotationEffect(.degrees(qiblaScreenAngle))
    }

    /// The hero arrow, pointing from the center toward the qibla.
    private var qiblaArrow: some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: 64))
            .foregroundStyle(tint)
            .rotationEffect(.degrees(qiblaScreenAngle))
            .shadow(color: tint.opacity(0.25), radius: 6)
    }

    /// Fixed marker at 12 o'clock = the direction you're facing.
    private var topReference: some View {
        Triangle()
            .fill(Color.secondary)
            .frame(width: 14, height: 10)
            .offset(y: -(radius + 2))
    }

    private var centerLabel: some View {
        Text(isAligned ? "Qibla" : "")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.green)
            .offset(y: 40)
    }

    /// Accumulate the shortest signed step so `displayHeading` stays continuous (it may grow past
    /// 360 or below 0); SwiftUI then interpolates the short way round.
    private func update(to new: Double) {
        var delta = (new - displayHeading).truncatingRemainder(dividingBy: 360)
        if delta > 180 { delta -= 360 }
        if delta < -180 { delta += 360 }
        displayHeading += delta
    }
}

private struct Cardinal: Identifiable {
    let label: String
    let angle: Double
    var id: String { label }
    static let all = [
        Cardinal(label: "N", angle: 0),
        Cardinal(label: "E", angle: 90),
        Cardinal(label: "S", angle: 180),
        Cardinal(label: "W", angle: 270),
    ]
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY)) // point downward into the dial
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
