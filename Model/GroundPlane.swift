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

struct GroundPlane
{
    // member variables
    var gpHeight: Float
    var gpWidth: Float
    var gpCenter: (Float, Float)
    var gpNode : SCNNode?
    var startNode : SCNNode?
    var goalNode : SCNNode?
    var obstacleNode : SCNNode?
    var pointCloudArray = [[SCNNode]]()
    
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
    
    func runSelectedAlgorithm(algorithm: String, heuristic: String)
    {
        switch algorithm
        {
//        case "Breadth-First":
//            return
//        case "Dijkstra's":
//            return
        case "A*":
            run_Astar(start: startNode!, goal: goalNode!, heuristic: heuristic)
            
        default:
            run_Astar(start: startNode!, goal: goalNode!, heuristic: heuristic)
        }
    }
    
    private func backtracePath(startNode:SCNNode, goalNode:SCNNode, nodeParentRecord:[SCNNode:SCNNode]) -> [SCNNode]
    {
        var optimalPath: [SCNNode] = [goalNode]
        var testList: [SCNNode] = [goalNode]
        
        while !testList.isEmpty
        {
            let currNode = testList.removeLast()
            
            if (currNode.name! == "Start")
            {
                break
            }
            
            let parent = nodeParentRecord[currNode]
            optimalPath.append(parent!)
            testList.append(parent!)
        }
        
        optimalPath.reverse()
        return optimalPath
    }
    
    private func calculateEuclideanDistance(currentNode: SCNNode, nextNode: SCNNode) -> Float
    {
        // XZ plane
        let absDiffX = currentNode.position.x - nextNode.position.x
        let absDiffZ = currentNode.position.z - nextNode.position.z
        let straightLineDistance = sqrtf(pow(absDiffX,2) + pow(absDiffZ,2))
        
        return straightLineDistance
    }
    
    private func getCurrentNodeIndex(nodeID: String) -> (Int,Int)
    {
        var nodeRow:Int = 0
        var nodeCol:Int = 0
        for i in 0...pointCloudArray.count-1
        {
            for j in 0...pointCloudArray[0].count-1
            {
                if pointCloudArray[i][j].name! == nodeID
                 {
                    print("FOUND NODE NAMED: \(nodeID) AT: i: \(i), j: \(j)")
                    nodeRow = i
                    nodeCol = j
                    break
                }
            }
        }
        return (nodeRow,nodeCol)
    }
    
    private func createPath(optimalPath: [SCNNode])
    {
        var linePointList: [SCNNode] = [optimalPath.first!]
        for currOptNode in optimalPath
        {
            if (currOptNode.name! != "Start") //&& (currOptNode.name! != "Goal")
            {
//                let sphereRadius: CGFloat = 0.01
//                let sphereGeometry = SCNSphere(radius: sphereRadius)
//                let sphereMaterial = SCNMaterial()
//                sphereMaterial.diffuse.contents = UIColor.green
//                sphereGeometry.materials = [sphereMaterial]
//
//                let pathNode = SCNNode()
//                pathNode.position = currOptNode.position
//                pathNode.geometry = sphereGeometry
//                pathNode.name = "Path"
//                gpNode!.replaceChildNode(currOptNode, with: pathNode)
                
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
                cylinder.firstMaterial?.diffuse.contents = UIColor.green
                
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
    
    private func run_Astar(start: SCNNode, goal: SCNNode, heuristic: String)
    {
        var activeHeuristic: ((SCNNode, SCNNode) -> Float)
        // determine the heuristic
        switch heuristic
        {
        case "Euclidean Distance":
            activeHeuristic = calculateEuclideanDistance(currentNode:nextNode:)
        default:
            activeHeuristic = calculateEuclideanDistance(currentNode:nextNode:)
        }
        
        let gridRowRange = 0...pointCloudArray.count-1
        let gridColRange = 0...pointCloudArray[0].count-1
        
        let pathCost: Float = 0.0
        let heuristicCost = activeHeuristic(start, goal)
        let fCost = pathCost + heuristicCost
        let startNodeInfo = (fCost,heuristicCost,pathCost,start.name!)
        var frontier = Heap<(Float, Float, Float, String)>(sort: <)
        var explored = [String]()
        var nodeParentRecord = [SCNNode : SCNNode]() // // keep track of nodes and their parent nodes
        var optimalPath = [SCNNode]()
        frontier.insert(startNodeInfo)
        nodeParentRecord[start] = nil
        
        // F-Cost = (G-Cost + H-Cost) where G is pathCost and H is heuristic cost
        // node: (priority,heuristicCost,pathCost,nodeID)
        while !frontier.isEmpty
        {
            let (_, _, currPathCost, currID) = frontier.remove()!
            // check to see if goal node has been popped
            if currID == "Goal"
            {
                optimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                break
            }
            explored.append(currID)
            
            // get current node position in grid
            let (currNodeRow, currNodecol) = getCurrentNodeIndex(nodeID: currID)
            let currNode = pointCloudArray[currNodeRow][currNodecol]
            let neighborLeft = (currNodeRow,currNodecol-1)
            let neighborRight = (currNodeRow,currNodecol+1)
            let neighborUp = (currNodeRow-1,currNodecol)
            let neighborDown = (currNodeRow+1,currNodecol)
            let neighborList : [(Int,Int)] = [neighborLeft, neighborRight, neighborUp, neighborDown]
            
            for neighborPos in neighborList
            {
                // check if neighbor exists in grid
                if (gridRowRange.contains(neighborPos.0) && gridColRange.contains(neighborPos.1))
                {
                    // check if neighbor node is an obstacle
                    if pointCloudArray[neighborPos.0][neighborPos.1].name! != "Obstacle"
                    {
                        let neighborNode = pointCloudArray[neighborPos.0][neighborPos.1]
                        let node2nodeCost = Float(0.05) // sphere separation distance
                        let currTotalPathCost = currPathCost + node2nodeCost
                        let neighborHeuristic = activeHeuristic(currNode,neighborNode)
                        let neighborFcost = currTotalPathCost + neighborHeuristic
                        let neighborNodeInfo = (neighborFcost,neighborHeuristic,currTotalPathCost,neighborNode.name!)
                        
                        if (!explored.contains(neighborNode.name!)) && (!frontier.nodes.contains { $0.3 == neighborNode.name! })
                        {
                            frontier.insert(neighborNodeInfo)
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                        }
                        else if (frontier.nodes.contains { $0.3 == neighborNode.name! })
                        {
                            // find and compare current node cost with node cost on frontier
                            let frontierIndex = frontier.nodes.firstIndex{$0.3 == neighborNode.name!}!
                            let (frontierFcost,_,_,_) = frontier.nodes[frontierIndex]
                            
                            if (frontierFcost > neighborFcost)
                            {
                                frontier.replace(index: frontierIndex, value: neighborNodeInfo)
                                nodeParentRecord[neighborNode] = currNode
                            }
                        }
                        
                    }
                }
            }
        }
        // do something with optimal path
        print("Optimal Path:")
        for optNode in optimalPath
        {
            print(optNode.name!)
        }
        createPath(optimalPath: optimalPath)
    }
    
}
