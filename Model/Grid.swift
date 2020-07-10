//
//  Grid.swift
//  PathPlannerAR
//
//  Created by David DeKime on 6/25/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

struct Grid
{
    // member variables
    private var gpHeight: Float
    private var gpWidth: Float
    private var gpCenter: (Float, Float)
    private var gpNode : SCNNode?
    private var startNode : SCNNode?
    private var goalNode : SCNNode?
    private var obstacleNode : SCNNode?
    private var pointCloudArray = [[SCNNode]]()
    private let nodeSeparationDistance: Float = 0.05
    
    init()
    {
        self.gpHeight = 0.0
        self.gpWidth = 0.0
        self.gpCenter = (0.0, 0.0)
        self.gpNode = nil
        self.startNode = nil
        self.goalNode = nil
    }
    
    mutating func setParams(groundPlaneAnchor: ARPlaneAnchor, groundPlaneNode: SCNNode)
    {
        self.gpHeight = groundPlaneAnchor.extent.z
        self.gpWidth = groundPlaneAnchor.extent.x
        self.gpCenter = (groundPlaneAnchor.center.x, groundPlaneAnchor.center.z)
        self.gpNode = groundPlaneNode
        
    }
    
    // member functions
    mutating func createPointCloud()
    {
        let groundPlaneStartZ = self.gpCenter.1 - self.gpHeight/2
        let groundPlaneHeight = self.gpHeight / 2
        let groundPlaneStartX = self.gpCenter.0 - self.gpWidth/2
        let groundPlaneWidth = self.gpWidth / 2
        let sphereSeparationDistance_m : Float = 1 / 20
        
        // create sphere geometry
        let sphereRadius: CGFloat = 0.01
        let sphereGeometry = SCNSphere(radius: sphereRadius)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.purple
        sphereGeometry.materials = [sphereMaterial]
        
        var nodeCount = 1
        var tempArray = [SCNNode]()
        for rowPos in stride(from: groundPlaneStartZ, to: groundPlaneHeight, by: sphereSeparationDistance_m)
        {
            for colPos in stride(from: groundPlaneStartX, to: groundPlaneWidth, by: sphereSeparationDistance_m)
            {
                // create sphere node
                let sphereNode = SCNNode()
                let sphereHoverDist: Float = 0.01
                sphereNode.position = SCNVector3(
                    x: colPos,
                    y: sphereHoverDist,
                    z: rowPos)
                sphereNode.geometry = sphereGeometry
                sphereNode.name = "N" + "\(nodeCount)"
                self.gpNode!.addChildNode(sphereNode)    // add sphere nodes to groundPlaneNode
                tempArray.append(sphereNode)
                nodeCount += 1
            }
            self.pointCloudArray.append(tempArray)  // add sphere nodes to 2D pointCloudArray
            tempArray.removeAll() // clear tempArray
        }
    }
    
    mutating func placeStartPoint(selectedNode: SCNNode)
    {
        guard let mapPointerScene = SCNScene(named: "art.scnassets/MapPointerGreen.scn"),
            let mapPointerNodeGreen = mapPointerScene.rootNode.childNode(withName: "MapPointerGreenRoot", recursively: false) else { return }
        mapPointerNodeGreen.position = selectedNode.position
        mapPointerNodeGreen.name = "Start"
        // replace sphere with 3D model
        gpNode!.replaceChildNode(selectedNode, with: mapPointerNodeGreen)
        
        startNode = mapPointerNodeGreen
        for i in 0...pointCloudArray.count-1
        {
            for j in 0...pointCloudArray[0].count-1
            {
                if pointCloudArray[i][j] == selectedNode
                {
                    print("SELECTED START NODE NAMED: \(selectedNode.name!) AT: i: \(i), j: \(j)")
                    print("RENAMING TO: \(mapPointerNodeGreen.name!)")
                    pointCloudArray[i][j] = mapPointerNodeGreen
                }
            }
        }
    }
    
    mutating func placeGoalPoint(selectedNode: SCNNode)
    {
        guard let mapPointerScene = SCNScene(named: "art.scnassets/MapPointerRed.scn"),
            let mapPointerNodeRed = mapPointerScene.rootNode.childNode(withName: "MapPointerRedRoot", recursively: false) else { return }
        mapPointerNodeRed.position = selectedNode.position
        mapPointerNodeRed.name = "Goal"
        // replace sphere with 3D model
        gpNode!.replaceChildNode(selectedNode, with: mapPointerNodeRed)
        
        goalNode = mapPointerNodeRed
        for i in 0...pointCloudArray.count-1
        {
            for j in 0...pointCloudArray[0].count-1
            {
                if pointCloudArray[i][j] == selectedNode
                {
                    print("SELECTED GOAL NODE NAMED: \(selectedNode.name!) AT: i: \(i), j: \(j)")
                    print("RENAMING TO: \(mapPointerNodeRed.name!)")
                    pointCloudArray[i][j] = mapPointerNodeRed
                }
            }
        }
    }
    
    mutating func placeObstacle(selectedNode: SCNNode)
    {
        guard let houseScene = SCNScene(named: "art.scnassets/GameHouse.scn"),
            let houseNode = houseScene.rootNode.childNode(withName: "HouseRoot", recursively: false) else { return }
        houseNode.position = selectedNode.position
        houseNode.name = "Obstacle"
        // replace sphere with 3D model
        gpNode!.replaceChildNode(selectedNode, with: houseNode)
        
        obstacleNode = houseNode
        for i in 0...pointCloudArray.count-1
        {
            for j in 0...pointCloudArray[0].count-1
            {
                if pointCloudArray[i][j] == selectedNode
                {
                    print("SELECTED OBSTACLE NODE NAMED: \(selectedNode.name!) AT: i: \(i), j: \(j)")
                    print("RENAMING TO: \(houseNode.name!)")
                    pointCloudArray[i][j] = houseNode
                }
            }
        }
    }
    
    public func createPath(optimalPath: [SCNNode], algorithm: String)
    {
        var linePointList: [SCNNode] = [optimalPath.first!]
        for currOptNode in optimalPath
        {
            if (currOptNode.name! != "Start") //&& (currOptNode.name! != "Goal")
            {
                // create line segments
                let x1 = linePointList.last!.position.x
                let x2 = currOptNode.position.x
                
                let y1 = linePointList.last!.position.y
                let y2 = currOptNode.position.y
                
                let z1 = linePointList.last!.position.z
                let z2 = currOptNode.position.z
                
                let distance =  sqrtf( (x2-x1) * (x2-x1) +
                    (y2-y1) * (y2-y1) +
                    (z2-z1) * (z2-z1) )
                
                let cylinder = SCNCylinder(radius: 0.005,
                                           height: CGFloat((distance)))
                cylinder.radialSegmentCount = 3
                
                if algorithm == "Breadth-First"
                {
                    cylinder.firstMaterial?.diffuse.contents = UIColor.yellow
                }
                else if algorithm == "Dijkstra's"
                {
                    cylinder.firstMaterial?.diffuse.contents = UIColor.red
                }
                else
                {
                    cylinder.firstMaterial?.diffuse.contents = UIColor.green
                }
                
                let lineNode = SCNNode(geometry: cylinder)
                lineNode.position = SCNVector3(x: (linePointList.last!.position.x + currOptNode.position.x) / 2,
                                               y: (linePointList.last!.position.y + currOptNode.position.y) / 2,
                                               z: (linePointList.last!.position.z + currOptNode.position.z) / 2)
                
                lineNode.eulerAngles = SCNVector3(Float.pi / 2,
                                                  acos((currOptNode.position.z-linePointList.last!.position.z)/distance),
                                                  atan2((currOptNode.position.y-linePointList.last!.position.y),(currOptNode.position.x-linePointList.last!.position.x)))
                
                gpNode!.addChildNode(lineNode)
                linePointList.append(currOptNode)
            }
        }
    }
    
   
    public func animateObjectAlongPath(optimalPath: [SCNNode])
    {
        var testPath = optimalPath
        let startNode = testPath.removeFirst()
        
        guard let roboScene = SCNScene(named: "art.scnassets/droidAgain.scn"),
            let roboNode = roboScene.rootNode.childNode(withName: "Droid", recursively: false) else { return }
        roboNode.position = startNode.position
        roboNode.name = "Robot"
        // replace sphere with 3D model
        //gpNode!.replaceChildNode(startNode, with: roboNode)
        
        self.gpNode!.addChildNode(roboNode)
        var sequence = [SCNAction]()
    
        for nextNode in testPath
        {
            let action = SCNAction.move(to: nextNode.position, duration: 3.0)
            sequence.append(action)
        }
        
        let actions = SCNAction.sequence(sequence)
        roboNode.runAction(actions)
        
    }
    
    // Getters
    public func getStartNode() -> SCNNode?
    {
        return startNode ?? nil
    }
    
    public func getGoalNode() -> SCNNode?
    {
        return goalNode ?? nil
    }
    
    public func getPointCloudArray() -> [[SCNNode]]
    {
        return pointCloudArray
    }
    
    public func getNodeSeparationDistance() -> Float
    {
        return nodeSeparationDistance
    }
    
    public func getGroundPlaneNode() -> SCNNode?
    {
        return gpNode ?? nil
    }
    
}
