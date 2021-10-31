//
//  InterfaceOrientationUpdater.swift
//  MetalScope
//
//  Created by Jun Tanaka on 2017/01/31.
//  Copyright © 2017 eje Inc. All rights reserved.
//

import SceneKit
import UIKit

internal final class InterfaceOrientationUpdater {
    let orientationNode: OrientationNode

    private var isTransitioning = false
    private var deviceOrientationDidChangeNotificationObserver: NSObjectProtocol?

    init(orientationNode: OrientationNode) {
        self.orientationNode = orientationNode
    }

    deinit {
        stopAutomaticInterfaceOrientationUpdates()
    }

    func updateInterfaceOrientation() {
        orientationNode.updateInterfaceOrientation()
    }

    func updateInterfaceOrientation(with transitionCoordinator: UIViewControllerTransitionCoordinator) {
        isTransitioning = true

        transitionCoordinator.animate(alongsideTransition: { context in
            SCNTransaction.lock()
            SCNTransaction.begin()
            SCNTransaction.animationDuration = context.transitionDuration
            SCNTransaction.animationTimingFunction = context.completionCurve.caMediaTimingFunction
            SCNTransaction.disableActions = !context.isAnimated

            self.updateInterfaceOrientation()

            SCNTransaction.commit()
            SCNTransaction.unlock()
        }, completion: { _ in
            self.isTransitioning = false
        })
    }

    func startAutomaticInterfaceOrientationUpdates() {
        guard deviceOrientationDidChangeNotificationObserver == nil else {
            return
        }

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        let observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard UIDevice.current.orientation.isValidInterfaceOrientation, self?.isTransitioning == false else {
                return
            }
            self?.updateInterfaceOrientation()
        }

        deviceOrientationDidChangeNotificationObserver = observer
    }

    func stopAutomaticInterfaceOrientationUpdates() {
        guard let observer = deviceOrientationDidChangeNotificationObserver else {
            return
        }

        UIDevice.current.endGeneratingDeviceOrientationNotifications()

        NotificationCenter.default.removeObserver(observer)

        deviceOrientationDidChangeNotificationObserver = nil
    }
}

private extension UIView.AnimationCurve {
    var caMediaTimingFunction: CAMediaTimingFunction {
        let name: CAMediaTimingFunctionName
        
        switch self {
        case .easeIn:
            name = CAMediaTimingFunctionName.easeIn
        case .easeOut:
            name = CAMediaTimingFunctionName.easeOut
        case .easeInOut:
            name = CAMediaTimingFunctionName.easeInEaseOut
        case .linear:
            name = CAMediaTimingFunctionName.linear
        default:
            name = CAMediaTimingFunctionName.default
        }
        
        return CAMediaTimingFunction(name: name)
    }
}
