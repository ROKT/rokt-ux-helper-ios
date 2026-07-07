//
//  FullScreenCheckoutExamples.swift
//  Example
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import RoktUXHelper
import SwiftUI
import UIKit

/// Full-screen modal used to exercise overlay presenter resolution (`experience-overlay.json` in the app bundle).
struct FullScreenCheckoutEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let experienceResource: String
    let layoutLocation: String
    let navigationTitle: String
    let onLayoutFailure: (() -> Void)

    var body: some View {
        NavigationView {
            SampleView(
                experienceResource: experienceResource,
                layoutLocation: layoutLocation,
                onLayoutFailure: onLayoutFailure
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

/// Presents `SampleViewController` from the key window using UIKit `.fullScreen`
/// (mirrors integrations that push checkout as a full-screen modal over the app root).
enum ExampleFullScreenCheckoutLauncher {

    /// Shallow stack: key-window top presenter → `UINavigationController` → `SampleViewController`.
    /// Overlay presenter resolution still succeeds if the resolver only follows `presentedViewController`
    /// from the window root (the checkout nav is on that chain).
    static func presentUIKitBottomSheetFlatFullScreenFromKeyWindow(
        experienceResource: String = "experience-bottomsheet",
        layoutLocation: String = "",
        navigationTitle: String = "Bottom sheet"
    ) {
        guard let root = keyWindowRootViewController() else { return }
        let sample = SampleViewController(experienceResource: experienceResource, layoutLocation: layoutLocation)
        let nav = UINavigationController(rootViewController: sample)
        nav.modalPresentationStyle = .fullScreen
        sample.title = navigationTitle
        sample.navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { _ in
                nav.dismiss(animated: true)
            }
        )
        topPresenter(from: root).present(nav, animated: true)
    }

    /// **Client-style topology:** `UITabBarController` → `UINavigationController` → leaf screen, and the
    /// **full-screen checkout** (with `SampleViewController` / Rokt) is `present`ed from that **leaf** —
    /// not as the key window root’s immediate `presentedViewController`. This matches apps where checkout
    /// sits under tab + navigation so SDK overlay presenter resolution must drill the stack (not only
    /// walk `root.presentedViewController` repeatedly).
    ///
    /// Flow: dismiss the outer shell with **Close** on the landing screen, then **Open full-screen checkout**
    /// to load Rokt; dismiss checkout with **Close** on the checkout nav.
    static func presentUIKitBottomSheetClientTopologyFromKeyWindow(
        experienceResource: String = "experience-bottomsheet",
        layoutLocation: String = "",
        checkoutNavigationTitle: String = "Bottom sheet"
    ) {
        presentClientTopologyShellFromKeyWindow(
            roktHost: .uiKit(
                experienceResource: experienceResource,
                layoutLocation: layoutLocation,
                navigationTitle: checkoutNavigationTitle
            )
        )
    }

    /// Same **tab → nav → leaf** shell as ``presentUIKitBottomSheetClientTopologyFromKeyWindow``,
    /// but checkout is SwiftUI ``SampleView`` / ``RoktLayoutView`` with **overlay** JSON — useful to
    /// exercise overlay presenter resolution for SwiftUI-hosted Rokt under a nested VC stack.
    static func presentSwiftUIOverlayClientTopologyFromKeyWindow(
        experienceResource: String = "experience-overlay",
        layoutLocation: String = "",
        checkoutNavigationTitle: String = "Overlay"
    ) {
        presentClientTopologyShellFromKeyWindow(
            roktHost: .swiftUI(
                experienceResource: experienceResource,
                layoutLocation: layoutLocation,
                navigationTitle: checkoutNavigationTitle
            )
        )
    }

    private static func presentClientTopologyShellFromKeyWindow(roktHost: ClientTopologyRoktHost) {
        guard let root = keyWindowRootViewController() else { return }
        let shell = ClientTopologyShellTabBarController(roktHost: roktHost)
        shell.modalPresentationStyle = .fullScreen
        topPresenter(from: root).present(shell, animated: true)
    }

    private static func keyWindowRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }

    private static func topPresenter(from root: UIViewController) -> UIViewController {
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - Client topology shell (tab → nav → leaf → present checkout)

/// What to present as the full-screen **checkout** from the navigation leaf (after **Open full-screen checkout**).
private enum ClientTopologyRoktHost {
    case uiKit(experienceResource: String, layoutLocation: String, navigationTitle: String)
    case swiftUI(experienceResource: String, layoutLocation: String, navigationTitle: String)
}

/// Hosts a single tab whose navigation stack ends at ``ClientTopologyLandingViewController``.
private final class ClientTopologyShellTabBarController: UITabBarController {

    init(roktHost: ClientTopologyRoktHost) {
        super.init(nibName: nil, bundle: nil)
        let landing = ClientTopologyLandingViewController(roktHost: roktHost)
        let innerNav = UINavigationController(rootViewController: landing)
        innerNav.tabBarItem = UITabBarItem(title: "Shop", image: nil, selectedImage: nil)
        viewControllers = [innerNav]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Leaf screen inside tab → nav; presents the full-screen checkout **from self** (nav visible VC).
private final class ClientTopologyLandingViewController: UIViewController {

    private let roktHost: ClientTopologyRoktHost

    init(roktHost: ClientTopologyRoktHost) {
        self.roktHost = roktHost
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Nested host"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.tabBarController?.dismiss(animated: true)
            }
        )

        let copy = """
        This flow mirrors a common partner topology: tab bar → navigation → screen, and checkout is a \
        `.fullScreen` modal presented from the navigation leaf — not from the window root’s next \
        `presentedViewController`. Rokt loads only after you open checkout below.
        """
        let label = UILabel()
        label.text = copy
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.title = "Open full-screen checkout (loads Rokt)"
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(openCheckout), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [label, button])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func openCheckout() {
        let checkoutNav: UINavigationController
        switch roktHost {
        case let .uiKit(experienceResource, layoutLocation, navigationTitle):
            let sample = SampleViewController(experienceResource: experienceResource, layoutLocation: layoutLocation)
            checkoutNav = UINavigationController(rootViewController: sample)
            sample.title = navigationTitle
            sample.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { _ in
                    checkoutNav.dismiss(animated: true)
                }
            )
        case let .swiftUI(experienceResource, layoutLocation, navigationTitle):
            let swiftUIRoot = SampleView(
                experienceResource: experienceResource,
                layoutLocation: layoutLocation,
                onLayoutFailure: nil
            )
            let hosting = UIHostingController(rootView: swiftUIRoot)
            hosting.view.backgroundColor = .systemBackground
            checkoutNav = UINavigationController(rootViewController: hosting)
            hosting.navigationItem.title = navigationTitle
            hosting.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { _ in
                    checkoutNav.dismiss(animated: true)
                }
            )
        }
        checkoutNav.modalPresentationStyle = .fullScreen
        present(checkoutNav, animated: true)
    }
}
