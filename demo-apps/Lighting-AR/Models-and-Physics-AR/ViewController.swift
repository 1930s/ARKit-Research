//
//  ViewController.swift
//  Models-and-Physics-AR
//
//  Created by Patrick Gatewood on 10/17/17.
//  Copyright © 2017 Patrick Gatewood. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    let bottomCollisionBitMask = 1 << 0 // 001 = 1
    let cubeCollisionBitMask = 1 << 1   // 010 = 2

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Detect horizontal planes in the scene
        configuration.planeDetection = .horizontal
        
        // Light the scene automatically
        sceneView.autoenablesDefaultLighting = true

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - Gesture Handling Action methods
    
    @IBAction func userTappedScreen(_ sender: UITapGestureRecognizer) {
        // Get the 2D point of the touch in the SceneView
        let tapPoint: CGPoint = sender.location(in: self.sceneView)
        
        // Conduct the hit test on the SceneView
        let hitTestResults: [ARHitTestResult] = sceneView.hitTest(tapPoint, types: .existingPlaneUsingExtent)
        
        if hitTestResults.isEmpty {
            return
        }
        
        // Arbitrarily pick the closest plane in the case of multiple results
        let result: ARHitTestResult = hitTestResults[0]
        
        // The position of the ARHitTestResult relative to the world coordinate system
        // The 3rd column in the matrix corresponds the the position of the point in the coordinate system
        let resultPositionMatrixColumn = result.worldTransform.columns.3
        
        // Position the node slightly above the hit test's position in order to show off gravity later
        let targetPosition: SCNVector3 = SCNVector3Make(resultPositionMatrixColumn.x, resultPositionMatrixColumn.y + /* insertion offset of ~50 cm */ 0.5, resultPositionMatrixColumn.z)
        
        addCubeAt(targetPosition)
    }
    
    // Adds a cube to the sceneView at the given position
    func addCubeAt(_ position: SCNVector3) {
        // .01 = roughly 10cm
        let cubeGeometry: SCNBox = SCNBox(
            width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        // Node that the geometry is applied to
        let cubeNode = SCNNode.init(geometry: cubeGeometry)
        cubeNode.position = position
        
        // Add Physics Body to the cube
        let physicsBody: SCNPhysicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: cubeGeometry, options: nil))
        physicsBody.mass = 1.5; // 1.5kg
        physicsBody.categoryBitMask = cubeCollisionBitMask
        physicsBody.restitution = 0.25
        physicsBody.friction = 0.75
        cubeNode.physicsBody = physicsBody
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(cubeNode)
    }
    
    // MARK: - Physics methods
    
    /**
     Sets up the "world bottom" - the death barrier that will remove any nodes that come in contact with it.
     */
    func setupWorldBottom() {
        let bottomNode: SCNNode = SCNNode(geometry: SCNBox(width: 1000, height: 1, length: 1000, chamferRadius: 0))
        
        // Make the bottom plane invisible
        bottomNode.opacity = 0
        
        // Place the bottom node below the ground to catch fallen cubes
        bottomNode.position = SCNVector3Make(0, -5, 0)
        
        // Give the bottom node collision physics
        let physicsBody: SCNPhysicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        physicsBody.categoryBitMask = bottomCollisionBitMask
    }
    
    /**
     Creates a new physics body for a plane SCNNode
     */
    func createPlanePhysicsBody(forNode: SCNNode, anchor: ARPlaneAnchor) {
        // Create a SCNBox the size of the plane, but 1cm high to prevent the cubes from clipping. SCNPlane has no height, so it is easily clipped through.
        let planeGeometry = SCNBox(width: CGFloat(anchor.extent.x) , height: CGFloat(anchor.extent.z), length: 0.005, chamferRadius: 0)
        
        // Give the plane a kinematic physics body so other nodes can interact with it, but it never moves and is unaffected by collisions
        let physicsBody: SCNPhysicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        
        physicsBody.restitution = 0.0
        physicsBody.friction = 1.0
        forNode.physicsBody = physicsBody
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    /**
     Tests if the cube collided with the bottom plane and removes it if true
     */
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if mask == [bottomCollisionBitMask, cubeCollisionBitMask] {
            if contact.nodeA.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }

    // MARK: - ARSCNViewDelegate
    
    /**
     Called when a new node is mapped to the passed in anchor
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Give the SCNNode a texture from Assets.xcassets to better visualize the detected plane.
        planeNode.geometry?.firstMaterial?.diffuse.contents = "grid.png" // NOTE: change this string to the name of the file you added
        
        createPlanePhysicsBody(forNode: planeNode, anchor: planeAnchor)
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
         */
        planeNode.eulerAngles.x = -.pi / 2
        
        // Make the plane visualization semitransparent to clearly show real-world placement.
        planeNode.opacity = 0.25
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
         */
        node.addChildNode(planeNode)
    }
    
    /**
     Called when the renderer updates its estimation of an existing node.
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)

        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)

        // Update the plane's physicsBody
        createPlanePhysicsBody(forNode: planeNode, anchor: planeAnchor)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
