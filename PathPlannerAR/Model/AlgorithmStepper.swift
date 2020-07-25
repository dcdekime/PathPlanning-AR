//
//  AlgorithmStepper.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/9/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class AlgorithmStepper : AlgorithmCommon
{
    // member variables
    let mGrid : Grid
    var mGroundPlaneNode : SCNNode
    let start : SCNNode
    let goal : SCNNode
    let pointCloudArray : [[SCNNode]]
    let nodeSeparationDistance : Float
    var frontier = Heap<(Float, Float, Float, String)>(sort: <)
    var explored = [String]()
    var nodeParentRecord = [SCNNode : SCNNode]() // // keep track of nodes and their parent nodes
    var optimalPath = [SCNNode]()
    var currNodeList = [SCNNode]()
    var neighborNodeList = [SCNNode]()
    var firstStep = true
    
    
    init(currGrid: Grid, heuristic: String)
    {
        mGrid = currGrid
        mGroundPlaneNode = currGrid.getGroundPlaneNode()!
        start = currGrid.getStartNode()!
        goal = currGrid.getGoalNode()!
        pointCloudArray = currGrid.getPointCloudArray()
        nodeSeparationDistance = currGrid.getNodeSeparationDistance()
        nodeParentRecord[start] = nil
    }
    
    private func visualizeCurrentNode(currNode: SCNNode)
    {
        // create sphere geometry
       let sphereRadius: CGFloat = 0.01
       let sphereGeometry = SCNSphere(radius: sphereRadius)
       let sphereMaterial = SCNMaterial()
       sphereMaterial.diffuse.contents = UIColor.red
       sphereGeometry.materials = [sphereMaterial]
        
        // create sphere node
        let sphereNode = SCNNode()
        sphereNode.position = currNode.position
        sphereNode.geometry = sphereGeometry
        sphereNode.name = "CurrentNode"
        mGroundPlaneNode.addChildNode(sphereNode)    // add sphere nodes to groundPlaneNode
    }
    
    private func visualizeNeighborNode(neighborNode: SCNNode)
    {
         // create sphere geometry
        let sphereRadius: CGFloat = 0.01
        let sphereGeometry = SCNSphere(radius: sphereRadius)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.yellow
        sphereGeometry.materials = [sphereMaterial]
         
         // create sphere node
         let sphereNode = SCNNode()
         sphereNode.position = neighborNode.position
         sphereNode.geometry = sphereGeometry
        sphereNode.name = "ExploredNode"
         mGroundPlaneNode.addChildNode(sphereNode)    // add sphere nodes to groundPlaneNode
    }
    
    private func removeNodeVisualization()
    {
       for currNode in currNodeList
        {
            currNode.removeFromParentNode()
        }
        
        for neighborNode in neighborNodeList
        {
            neighborNode.removeFromParentNode()
        }
    }

    public func step_Astar(heuristic: String)
    {
        print("RUNNING STEPPER A*")
        removeNodeVisualization()
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

        if firstStep
        {
            let pathCost : Float = 0.0
            let heuristicCost : Float = activeHeuristic(start,goal)
            let fCost = pathCost + heuristicCost
            let startNodeInfo = (fCost,heuristicCost,pathCost,start.name!)
            frontier.insert(startNodeInfo)
            firstStep = false
        }
        // F-Cost = (G-Cost + H-Cost) where G is pathCost and H is heuristic cost
        // node: (priority,heuristicCost,pathCost,nodeID)
        if !frontier.isEmpty
        {
            let (_, _, currPathCost, currID) = frontier.remove()!
            // check to see if goal node has been popped
            if currID == "Goal"
            {
                optimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
            }
            explored.append(currID)

            // get current node position in grid
            let (currNodeRow, currNodecol) = getCurrentNodeIndex(pointCloudArray: pointCloudArray, nodeID: currID)
            let currNode = pointCloudArray[currNodeRow][currNodecol]
            visualizeCurrentNode(currNode: currNode)
            
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
                        let node2nodeCost = nodeSeparationDistance
                        let currTotalPathCost = currPathCost + node2nodeCost
                        let neighborHeuristic = activeHeuristic(currNode,neighborNode)
                        let neighborFcost = currTotalPathCost + neighborHeuristic
                        let neighborNodeInfo = (neighborFcost,neighborHeuristic,currTotalPathCost,neighborNode.name!)

                        if (!explored.contains(neighborNode.name!)) && (!frontier.nodes.contains { $0.3 == neighborNode.name! })
                        {
                            frontier.insert(neighborNodeInfo)
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                            visualizeNeighborNode(neighborNode: neighborNode)
                            neighborNodeList.append(neighborNode)
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
//        // do something with optimal path
//        mGrid.createPath(optimalPath: optimalPath)
//        print("Stepper A* Optimal Path:")
//        for optNode in optimalPath
//        {
//            print(optNode.name!)
//        }
//        mGrid.animateObjectAlongPath(optimalPath: optimalPath)
    }
}
