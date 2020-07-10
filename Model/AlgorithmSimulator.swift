//
//  AlgorithmSimulator.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/9/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class AlgorithmSimulator : AlgorithmCommon
{
    // member variables
    let mGrid : Grid
    let start : SCNNode
    let goal : SCNNode
    let pointCloudArray : [[SCNNode]]
    let nodeSeparationDistance : Float
    
    init(currGrid: Grid)
    {
        mGrid = currGrid
        start = currGrid.getStartNode()!
        goal = currGrid.getGoalNode()!
        pointCloudArray = currGrid.getPointCloudArray()
        nodeSeparationDistance = currGrid.getNodeSeparationDistance()
    }
    
    public func run_BFS()
    {
        print("RUNNING BFS!!")
        let gridRowRange = 0...pointCloudArray.count-1
        let gridColRange = 0...pointCloudArray[0].count-1
        var frontier: [String] = []
        var explored: Set<String> = []
        var nodeParentRecord = [SCNNode : SCNNode]()
        var optimalPath = [SCNNode]()
        
        frontier.append(start.name!)
        nodeParentRecord[start] = nil
        
        outerLoop: while !frontier.isEmpty
        {
            let currID = frontier.removeFirst()
            explored.insert(currID)
            
            let (currNodeRow, currNodecol) = getCurrentNodeIndex(pointCloudArray: pointCloudArray, nodeID: currID)
            let currNode = pointCloudArray[currNodeRow][currNodecol]
            let neighborLeft = (currNodeRow,currNodecol-1)
            let neighborRight = (currNodeRow,currNodecol+1)
            let neighborUp = (currNodeRow-1,currNodecol)
            let neighborDown = (currNodeRow+1,currNodecol)
            let neighborList : [(Int,Int)] = [neighborLeft, neighborRight, neighborUp, neighborDown]
            
            innerLoop: for neighborPos in neighborList
            {
                // check if neighbor exists in grid
                if (gridRowRange.contains(neighborPos.0) && gridColRange.contains(neighborPos.1))
                {
                    // check if neighbor node is an obstacle
                    if pointCloudArray[neighborPos.0][neighborPos.1].name! != "Obstacle"
                    {
                        let neighborNode = pointCloudArray[neighborPos.0][neighborPos.1]
                        if (!explored.contains(neighborNode.name!) && (!frontier.contains(currID)))
                        {
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                            if neighborNode.name! == "Goal"
                            {
                                optimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                                break outerLoop
                            }
                            frontier.append(neighborNode.name!)
                        }
                    }
                }
            }
        }
        // do something with optimal path
        print("BFS Optimal Path:")
        for optNode in optimalPath
        {
            print(optNode.name!)
        }
        mGrid.createPath(optimalPath: optimalPath, algorithm: "Breadth-First")
    }
    
    public func run_Dijkstra()
    {
        print("RUNNING DIJKSTRA:")
        let gridRowRange = 0...pointCloudArray.count-1
        let gridColRange = 0...pointCloudArray[0].count-1
        
        let pathCost: Float = 0.0
        let startNodeInfo = (pathCost,start.name!)
        var frontier = Heap<(Float, String)>(sort: <)
        var explored = [String]()
        var nodeParentRecord = [SCNNode : SCNNode]() // // keep track of nodes and their parent nodes
        var optimalPath = [SCNNode]()
        frontier.insert(startNodeInfo)
        nodeParentRecord[start] = nil
        
        while !frontier.isEmpty
        {
            let (currPathCost, currID) = frontier.remove()!
            // check to see if goal node has been popped
            if currID == "Goal"
            {
                optimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                break
            }
            explored.append(currID)
            
            // get current node position in grid
            let (currNodeRow, currNodecol) = getCurrentNodeIndex(pointCloudArray: pointCloudArray, nodeID: currID)
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
                        let node2nodeCost = nodeSeparationDistance
                        let neighborTotalPathCost = currPathCost + node2nodeCost
                        let neighborNodeInfo = (neighborTotalPathCost,neighborNode.name!)
                        
                        if (!explored.contains(neighborNode.name!)) && (!frontier.nodes.contains { $0.1 == neighborNode.name! })
                        {
                            frontier.insert(neighborNodeInfo)
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                        }
                        else if (frontier.nodes.contains { $0.1 == neighborNode.name! })
                        {
                            // find and compare current node cost with node cost on frontier
                            let frontierIndex = frontier.nodes.firstIndex{$0.1 == neighborNode.name!}!
                            let (frontierPathcost,_) = frontier.nodes[frontierIndex]
                            
                            if (frontierPathcost > neighborTotalPathCost)
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
        print("Dijkstra's Optimal Path:")
        for optNode in optimalPath
        {
            print(optNode.name!)
        }
        mGrid.createPath(optimalPath: optimalPath, algorithm: "Dijkstra's")
    }
    
    public func run_Astar(heuristic: String)
    {
        print("RUNNING A*")
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
            let (currNodeRow, currNodecol) = getCurrentNodeIndex(pointCloudArray: pointCloudArray, nodeID: currID)
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
                        let node2nodeCost = nodeSeparationDistance
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
        mGrid.createPath(optimalPath: optimalPath, algorithm: "A*")
        print("A* Optimal Path:")
        for optNode in optimalPath
        {
            print(optNode.name!)
        }
        mGrid.animateObjectAlongPath(optimalPath: optimalPath)
    }
}
