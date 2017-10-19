//
//  ViewController.swift
//  Halloscene
//
//  Created by Victor Nouvellet on 10/19/17.
//  Copyright © 2017 Victor Nouvellet. All rights reserved.
//

import UIKit

class HSViewController: UIViewController {
    
    // UI Elements
    @IBOutlet weak var ballImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // Animator properties
    var animator: UIDynamicAnimator? = nil
    var snapBehavior: UISnapBehavior? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set animator reference to container view
        self.animator = UIDynamicAnimator(referenceView: containerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.configureGravity()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Interface Builder methods
    
    @IBAction func tapDetected(_ gesture: UIGestureRecognizer) {
        if gesture.numberOfTouches == 2 {
            self.removeSnapBehavior()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            self.snap(at: touches.first!.location(in: self.containerView))
        }
    }
    
    // MARK: Private methods
    
    private func configureGravity() {
        let gravityBehavior = UIGravityBehavior(items: [self.ballImageView])
        self.animator?.addBehavior(gravityBehavior)
        
        let collisionBehavior = UICollisionBehavior(items: [self.ballImageView])
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.animator?.addBehavior(collisionBehavior)
        
        let elasticityBehavior = UIDynamicItemBehavior(items: [self.ballImageView])
        elasticityBehavior.elasticity = 0.7
        self.animator?.addBehavior(elasticityBehavior)
    }
}

// MARK: - Snap-related methods extension

extension HSViewController {
    fileprivate func snap(at point: CGPoint) {
        self.removeSnapBehavior()
        
        let snapBehavior = UISnapBehavior(item: self.ballImageView, snapTo: point)
        self.animator?.addBehavior(snapBehavior)
        
        self.snapBehavior = snapBehavior
    }
    
    fileprivate func removeSnapBehavior() {
        if let oldSnapBehavior = self.snapBehavior {
            self.animator?.removeBehavior(oldSnapBehavior)
        }
    }
}

