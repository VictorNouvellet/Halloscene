//
//  ViewController.swift
//  Halloscene
//
//  Created by Victor Nouvellet on 10/19/17.
//  Copyright © 2017 Victor Nouvellet. All rights reserved.
//

import UIKit
import CoreMotion

class HSViewController: UIViewController {
    
    // UI Elements
    @IBOutlet weak var ballImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    // Animator properties
    var animator: UIDynamicAnimator?
    var snapBehavior: UISnapBehavior?
    var gravityBehavior: UIGravityBehavior?
    
    // Motion properties
    var motionManager = CMMotionManager()
    var motionQueue = OperationQueue()
    
    // Other properties
    var scaryBall: Bool = false
    var labelTimer: Timer? = nil
    var particleEmitter = CAEmitterLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set animator reference to container view
        self.animator = UIDynamicAnimator(referenceView: containerView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Configure Animator and Particles
        self.configureCollisionAndElasticity()
        self.configureMotion()
        self.configureParticles()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 && self.containerView.frame.contains(touches.first!.location(in: self.containerView)) {
            self.removeGravity()
            let touch = touches.first!
            if touch.tapCount == 1 {
                DispatchQueue.main.async {
                    self.snap(at: touches.first!.location(in: self.containerView))
                }
            } else {
                DispatchQueue.main.async {
                    self.removeSnapBehavior()
                    self.configureMotion()
                }
            }
        } else if touches.count == 2 {
            self.changeBallImage()
        }
    }
    
    // MARK: Interface Builder methods
    
    @IBAction func ballLongPressHandle(_ gesture: UIGestureRecognizer) {
        // Emit candies particles
        switch gesture.state {
        case .began:
            createParticles()
            break
        case .cancelled, .ended:
            self.particleEmitter.emitterCells = []
            break
        default:
            break
        }
    }
    
    // MARK: Private methods
    
    private func configureCollisionAndElasticity() {
        let collisionBehavior = UICollisionBehavior(items: [self.ballImageView])
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        self.animator?.addBehavior(collisionBehavior)
        
        let elasticityBehavior = UIDynamicItemBehavior(items: [self.ballImageView])
        elasticityBehavior.elasticity = 0.7
        self.animator?.addBehavior(elasticityBehavior)
    }
    
    private func changeBallImage() {
        self.scaryBall = !self.scaryBall
        // TODO: Swap images on layer level
        self.ballImageView.image = self.scaryBall ? #imageLiteral(resourceName: "HallosceneBallScary") : #imageLiteral(resourceName: "HallosceneBall")
        if self.scaryBall {
            self.helloJack()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setIcon()
            }
        }
    }
    
    private func setIcon() {
        let today = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        if day == 20 && month == 10 {
            print("Yeah! It is Halloween")
            if UIApplication.shared.alternateIconName == nil {
                UIApplication.shared.setAlternateIconName("AppIconHalloween", completionHandler: { (error) in
                    print("Changed icon to Halloween icon. Error: \(String(describing: error?.localizedDescription))")
                })
            }
        } else {
            print("Ohhh! It is not Halloween")
            if UIApplication.shared.alternateIconName != nil {
                UIApplication.shared.setAlternateIconName(nil, completionHandler: { (error) in
                    print("Changed icon to normal icon. Error: \(String(describing: error?.localizedDescription))")
                })
            }
        }
    }
    
    private func helloJack() {
        self.messageLabel.text = "Hello Jack!"
        self.messageLabel.isHidden = false
        
        self.labelTimer?.invalidate()
        self.labelTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) in
            self.messageLabel.isHidden = true
        })
    }
}

// MARK: - Gravition related methods extension

extension HSViewController {
    fileprivate func configureGravity() {
        self.gravityBehavior = UIGravityBehavior(items: [self.ballImageView])
        self.gravityBehavior!.magnitude = 0.8
        self.animator?.addBehavior(self.gravityBehavior!)
    }
    
    fileprivate func removeGravity() {
        if let safeGravityBehavior = self.gravityBehavior {
            self.animator?.removeBehavior(safeGravityBehavior)
        }
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

// MARK: - Motion methods extension

extension HSViewController {
    fileprivate func configureMotion() {
        self.removeGravity()
        self.configureGravity()
        
        motionManager.startDeviceMotionUpdates(to: motionQueue) { (deviceMotion, error) in
            if let safeError = error {
                print("\(safeError)")
            }
            
            guard let safeDeviceMotion = deviceMotion else {
                print("Error: Device Motion not available")
                return
            }
            
            let grav : CMAcceleration = safeDeviceMotion.gravity;
            
            let x = CGFloat(grav.x);
            let y = CGFloat(-grav.y);
            
            let v = CGVector(dx: x, dy: y)
            
            OperationQueue.main.addOperation {
                self.gravityBehavior?.gravityDirection = v
                self.ballImageView.transform = CGAffineTransform(rotationAngle: CGFloat(atan2(grav.x, grav.y)) - CGFloat.pi)
            }
        }
    }
}

// MARK: - Particles methods extension

extension HSViewController {
    fileprivate func configureParticles() {
        particleEmitter.emitterPosition = CGPoint(x: view.center.x, y: -96)
        particleEmitter.emitterShape = kCAEmitterLayerLine
        particleEmitter.emitterSize = CGSize(width: view.frame.size.width, height: 1)
        
        view.layer.insertSublayer(particleEmitter, below: containerView.layer) //.addSublayer(particleEmitter)
    }
    
    fileprivate func createParticles() {
        let orangeCandy = makeCandyEmitterCell(color: UIColor.orange)
        let ghost = makeGhostEmitterCell()
        particleEmitter.emitterCells = [orangeCandy, ghost]
    }
    
    fileprivate func makeCandyEmitterCell(color: UIColor) -> CAEmitterCell {
        return self.makeEmitterCell(color: color, image: #imageLiteral(resourceName: "Candy"))
    }
    
    fileprivate func makeGhostEmitterCell() -> CAEmitterCell {
        return self.makeEmitterCell(color: .black, image: #imageLiteral(resourceName: "Ghost"))
    }
    
    fileprivate func makeEmitterCell(color: UIColor, image: UIImage?) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 5
        cell.lifetime = 7.0
        cell.lifetimeRange = 0
        cell.color = color.cgColor
        cell.velocity = 300
        cell.velocityRange = 50
        cell.emissionLongitude = CGFloat.pi
        cell.emissionRange = CGFloat.pi / 4
        cell.spin = 2
        cell.spinRange = 3
        cell.scaleRange = 0.5
        cell.scaleSpeed = -0.05
        
        cell.contents = image?.cgImage
        return cell
    }
}

