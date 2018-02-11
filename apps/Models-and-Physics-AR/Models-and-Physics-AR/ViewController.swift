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

class ViewController: UIViewController, ARSCNViewDelegate {

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
        let cubeGeometry: SCNBox = SCNBox.init(
            width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        // Node that the geometry is applied to
        let cubeNode = SCNNode.init(geometry: cubeGeometry)
        cubeNode.position = position
        
        // Add Physics Body to the cube
        let physicsBody: SCNPhysicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.dynamic, shape: nil)
        physicsBody.mass = 1.0; // 1kg
        cubeNode.physicsBody = physicsBody
        
        // Add the node to the scene
        sceneView.scene.rootNode.addChildNode(cubeNode)
        
        sceneView.autoenablesDefaultLighting = true
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Give the SCNNode a texture from Assets.xcassets to better visualize the detected plane.
        planeNode.geometry?.firstMaterial?.diffuse.contents = "grid.png" // NOTE: change this string to the name of the file you added
        
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
