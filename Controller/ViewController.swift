//
//  ViewController.swift
//  PathPlannerAR
//
//  Created by David DeKime on 6/22/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate
{
    // member variables
    @IBOutlet weak var algoButton1: UIButton!
    @IBOutlet weak var algoButton2: UIButton!
    @IBOutlet weak var obstacleButtonDesign: UIButton!
    @IBOutlet weak var startButtonDesign: UIButton!
    @IBOutlet weak var goalButtonDesign: UIButton!
    @IBOutlet weak var resetButtonDesign: UIButton!
    @IBOutlet weak var generatePathButtonDesign: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    var algorithmSelected = ""
    var heuristicSelected = ""
    var gridObject = Grid()
    var selectedSphere: SCNNode?

    var groundPlaneFound = false
    var startButtonPushed = false
    var startNodeSelected = false
    var goalButtonPushed = false
    var goalNodeSelected = false
    var obstacleButtonPushed = false
    var obstacleNodeSelected = false
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addCoaching()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
        // Set view lighting
        sceneView.autoenablesDefaultLighting = true
        
        obstacleButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-home-page-48.png"), for: .normal)
        
        startButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-address-64.png"), for: .normal)
        
        goalButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-finish-flag-64.png"), for: .normal)
        
        resetButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-reset-48.png"), for: .normal)
        
        switch algorithmSelected
        {
           case "Breadth-First":
                algoButton1.setTitle("Dijkstra's", for: .normal)
                algoButton2.setTitle("A*", for: .normal)
           case "Dijkstra's":
               algoButton1.setTitle("Breadth-First", for: .normal)
               algoButton2.setTitle("A*", for: .normal)
           case "A*":
               algoButton1.setTitle("Breadth-First", for: .normal)
               algoButton2.setTitle("Dijkstra's", for: .normal)
               
           default:
               algoButton1.setTitle("Dijkstra's", for: .normal)
               algoButton2.setTitle("A*", for: .normal)
       }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        if anchor is ARPlaneAnchor && !self.groundPlaneFound
        {
            // convert anchor to planeAnchor type
            let planeAnchor = anchor as! ARPlaneAnchor
            self.groundPlaneFound = true
            
            // create plane material
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")

            // create plane geometry
            let plane = SCNPlane(
                width: CGFloat(planeAnchor.extent.x),
                height: CGFloat(planeAnchor.extent.z)
            )
            plane.materials = [gridMaterial]
            
            // create plane node
            let planeNode = SCNNode()
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            
            // rotate plane from vertical to horizontal position
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            planeNode.geometry = plane

            // add child node(s)
            node.addChildNode(planeNode)
            
            // create GroundPlane object
            self.gridObject.setParams(groundPlaneAnchor: planeAnchor, groundPlaneNode: node)
            self.gridObject.createPointCloud() // create spheres across ground plane
        }
        else
        {
            return
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let touch = touches.first
        {
            let touchLocation = touch.location(in: sceneView)

            let results = sceneView.hitTest(touchLocation, options: nil)

            if let hitResult = results.first
            {
                handleTouchFor(selectedNode: hitResult.node) // Handle the virtual object selected by user
            }
        }
    }
    
    func handleTouchFor(selectedNode: SCNNode)
    {
        if selectedNode.geometry is SCNSphere
        {
            if (self.startButtonPushed && !self.startNodeSelected)
            {
                gridObject.placeStartPoint(selectedNode: selectedNode)
                // reset boolean flags so that other nodes selected will not be affected
                self.startNodeSelected = true
                self.startButtonPushed = false
            }
            else if (self.goalButtonPushed && !self.goalNodeSelected)
            {
                gridObject.placeGoalPoint(selectedNode: selectedNode)
                self.goalNodeSelected = true
                self.goalButtonPushed = false
            }
            else if (self.obstacleButtonPushed && !self.obstacleNodeSelected)
            {
                gridObject.placeObstacle(selectedNode: selectedNode)
                self.obstacleNodeSelected = true
                self.obstacleButtonPushed = false
            }
            else
            {
                return
            }
        }
    }
    
    func showAlert()
    {
        let alertController = UIAlertController(title: "Generate Path", message:
            "Please select a start and a goal point", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))

        self.present(alertController, animated: true, completion: nil)
    }
    
    // AR Button Logic
    @IBAction func obstacleButton(_ sender: UIButton)
    {
        self.obstacleButtonPushed = true
        self.obstacleNodeSelected = false
    }
    
    @IBAction func startButton(_ sender: UIButton)
    {
        self.startButtonPushed = true
        self.startNodeSelected = false
    }
    
    @IBAction func goalButton(_ sender: UIButton)
    {
        self.goalButtonPushed = true
        self.goalNodeSelected = false
    }
    
    
    @IBAction func resetPlanePos(_ sender: Any)
    {
        restartSession()
    }
    
    func restartSession()
    {
        self.gridObject = Grid()    // create a new Grid
        groundPlaneFound = false
        startNodeSelected = false
        goalNodeSelected = false
        sceneView.session.pause()
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in node.removeFromParentNode() }
        if let configuration = sceneView.session.configuration
        {
            sceneView.session.run(configuration,
                                  options: [.resetTracking, .removeExistingAnchors])
        }
    }
    
    @IBAction func generatePath(_ sender: UIButton)
    {
        if startNodeSelected && goalNodeSelected
        {
            //let algorithmStepper = AlgorithmStepper(currGrid: gridObject, heuristic: heuristicSelected)
            // pass along current grid to algorithm handler
            let algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: algorithmSelected, heuristic: heuristicSelected)
            algoHandler.runSelectedAlgorithm()
        }
        else
        {
            showAlert()
        }
    }
    
    @IBAction func algorithmOverlay1(_ sender: UIButton)
    {
        print(sender.titleLabel!.text!)
        if startNodeSelected && goalNodeSelected
        {
            //let algorithmStepper = AlgorithmStepper(currGrid: gridObject, heuristic: heuristicSelected)
            // pass along current grid to algorithm handler
            let algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: sender.titleLabel!.text!, heuristic: heuristicSelected)
            algoHandler.runSelectedAlgorithm()
        }
        else
        {
            showAlert()
        }
        
    }
    
    @IBAction func algorithmOverlay2(_ sender: UIButton)
    {
        print(sender.titleLabel!.text!)
        if startNodeSelected && goalNodeSelected
        {
            //let algorithmStepper = AlgorithmStepper(currGrid: gridObject, heuristic: heuristicSelected)
            // pass along current grid to algorithm handler
            let algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: sender.titleLabel!.text!, heuristic: heuristicSelected)
            algoHandler.runSelectedAlgorithm()
        }
        else
        {
            showAlert()
        }
    }
    
    
}

extension ViewController: ARCoachingOverlayViewDelegate {
  func addCoaching() {
    // Create a ARCoachingOverlayView object
    let coachingOverlay = ARCoachingOverlayView()
    // Make sure it rescales if the device orientation changes
    coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coachingOverlay.center = self.sceneView.center
    self.sceneView.addSubview(coachingOverlay)
    // Set the Augmented Reality goal
    coachingOverlay.goal = .horizontalPlane
    // Set the ARSession
    coachingOverlay.session = self.sceneView.session
    // Set the delegate for any callbacks
    coachingOverlay.delegate = self
  }
  // Example callback for the delegate object
  func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView)
  {
    print("DID THE COACHING THING!")
  }
}
