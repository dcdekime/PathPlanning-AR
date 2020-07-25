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
    @IBOutlet weak var backButtonDesign: UIButton!
    @IBOutlet weak var pathDetailsButtonDesign: UIButton!
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
    
    var bfsPathModel = PathModel()
    var dijkstraPathModel = PathModel()
    var aStarPathModel = PathModel()
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addCoaching()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        
        // Set view lighting
        sceneView.autoenablesDefaultLighting = true
        
        let rightRecognizer = UISwipeGestureRecognizer(target: self, action:
        #selector(swipeMade(_:)))
           rightRecognizer.direction = .right
        sceneView.addGestureRecognizer(rightRecognizer)
        
        obstacleButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-home-page-48.png"), for: .normal)
        
        startButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-address-64.png"), for: .normal)
        
        goalButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-finish-flag-64.png"), for: .normal)
        
        resetButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-reset-48.png"), for: .normal)
        
        backButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/icons8-go-back-64.png"), for: .normal)
        
        pathDetailsButtonDesign.setBackgroundImage(UIImage(named: "art.scnassets/goForward.png"), for: .normal)
        
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
    
    @IBAction func swipeMade(_ sender: UISwipeGestureRecognizer)
    {
        if sender.direction == .right
        {
            print("right swipe made")
            performSegue(withIdentifier: "toAlgorithmOptions", sender: self)
        }
        else if sender.direction == .left
        {
            print("left swipe made")
            
        }
    }
    
    func showAlert(errorCode: Int)
    {
        if errorCode == 0
        {
            let alertController = UIAlertController(title: "Generate Path", message:
                "Please select a start and a goal point", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))

            self.present(alertController, animated: true, completion: nil)
        }
        else if errorCode == 1
        {
            let alertController = UIAlertController(title: "No Valid Path ", message:
                "Please select new obstacle points", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))

            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func goalFound(optimalPath: [SCNNode]) -> Bool
    {
        var goalFound = false
        for optNode in optimalPath
        {
            if optNode.name! == "Goal"
            {
                goalFound = true
            }
        }
        
        return goalFound
    }
    
    func setPathParameters(currPathModel: PathModel, algoSelected: String)
    {
        switch algoSelected
         {
            case "Breadth-First":
                bfsPathModel.setPath(optPath: currPathModel.getPath())
                bfsPathModel.setExploredLength(exploredLength: currPathModel.getExploredLength())
                bfsPathModel.setFrontierLength(frontierLength: currPathModel.getFrontierLength())
                if !goalFound(optimalPath: bfsPathModel.getPath())
                {
                    showAlert(errorCode: 1)
                    restartSession()
                }
            case "Dijkstra's":
                dijkstraPathModel.setPath(optPath: currPathModel.getPath())
                dijkstraPathModel.setExploredLength(exploredLength: currPathModel.getExploredLength())
                dijkstraPathModel.setFrontierLength(frontierLength: currPathModel.getFrontierLength())
                if !goalFound(optimalPath: dijkstraPathModel.getPath())
                {
                    showAlert(errorCode: 1)
                    restartSession()
                }
            case "A*":
                aStarPathModel.setPath(optPath: currPathModel.getPath())
                aStarPathModel.setExploredLength(exploredLength: currPathModel.getExploredLength())
                aStarPathModel.setFrontierLength(frontierLength: currPathModel.getFrontierLength())
                if !goalFound(optimalPath: aStarPathModel.getPath())
                {
                    showAlert(errorCode: 1)
                    restartSession()
                }
            default:
                aStarPathModel.setPath(optPath: currPathModel.getPath())
                aStarPathModel.setExploredLength(exploredLength: currPathModel.getExploredLength())
                aStarPathModel.setFrontierLength(frontierLength: currPathModel.getFrontierLength())
                if !goalFound(optimalPath: aStarPathModel.getPath())
                {
                    showAlert(errorCode: 1)
                    restartSession()
                }
        }
    }
    
    // AR Button Logic
    @IBAction func backtoAlgoScreen(_ sender: UIButton)
    {
        performSegue(withIdentifier: "toAlgorithmOptions", sender: self)
    }
    
    
    @IBAction func toDetailsScreen(_ sender: UIButton)
    {
        if startNodeSelected && goalNodeSelected
        {
            performSegue(withIdentifier: "toDetailScreen", sender: self)
        }
        else
        {
            showAlert(errorCode: 0)
        }
    }
    
     // gets called just before segue occurs
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "toAlgorithmOptions"
        {

        }
        else if segue.identifier == "toDetailScreen"
        {
            let destinationVC = segue.destination as! pathDetailController
            
            // set bfs parameters
            destinationVC.bfsPL = String(bfsPathModel.getPath().count)
            destinationVC.bfsNE = String(bfsPathModel.getExploredLength())
            destinationVC.bfsFL = String(bfsPathModel.getFrontierLength())
            
            // set dijkstra parameters
            destinationVC.dijkstraPL = String(dijkstraPathModel.getPath().count)
            destinationVC.dijkstraNE = String(dijkstraPathModel.getExploredLength())
            destinationVC.dijkstraFL = String(dijkstraPathModel.getFrontierLength())

            // set A* parameters
            destinationVC.aStarPL = String(aStarPathModel.getPath().count)
            destinationVC.aStarNE = String(aStarPathModel.getExploredLength())
            destinationVC.aStarFL = String(aStarPathModel.getFrontierLength())
        }
    }
    
    
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
        self.bfsPathModel = PathModel()
        self.dijkstraPathModel = PathModel()
        self.aStarPathModel = PathModel()
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
            var tempPathModel = PathModel()
            var algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: algorithmSelected, heuristic: heuristicSelected, pathModel: tempPathModel)
            tempPathModel = algoHandler.runSelectedAlgorithm()
            setPathParameters(currPathModel: tempPathModel, algoSelected: algorithmSelected)
            
        }
        else
        {
            showAlert(errorCode: 0)
        }
    }
    
    @IBAction func algorithmOverlay1(_ sender: UIButton)
    {
        print(sender.titleLabel!.text!)
        if startNodeSelected && goalNodeSelected
        {
            var tempPathModel = PathModel()
            var algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: sender.titleLabel!.text!, heuristic: heuristicSelected, pathModel: tempPathModel)
            tempPathModel = algoHandler.runSelectedAlgorithm()
            setPathParameters(currPathModel: tempPathModel, algoSelected: sender.titleLabel!.text!)
        }
        else
        {
            showAlert(errorCode: 0)
        }
        
    }
    
    @IBAction func algorithmOverlay2(_ sender: UIButton)
    {
        print(sender.titleLabel!.text!)
        if startNodeSelected && goalNodeSelected
        {
            var tempPathModel = PathModel()
            var algoHandler = AlgorithmHandler(currGrid: gridObject, algorithm: sender.titleLabel!.text!, heuristic: heuristicSelected, pathModel: tempPathModel)
            tempPathModel = algoHandler.runSelectedAlgorithm()
            setPathParameters(currPathModel: tempPathModel, algoSelected: sender.titleLabel!.text!)
        }
        else
        {
            showAlert(errorCode: 0)
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

