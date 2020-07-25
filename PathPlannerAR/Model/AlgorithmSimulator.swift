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
    
    public func run_BFS() -> ([String], Set<String>, [SCNNode])
    {
        print("RUNNING BFS!!")
        let gridRowRange = 0...pointCloudArray.count-1
        let gridColRange = 0...pointCloudArray[0].count-1
        var bfsFrontier: [String] = []
        var bfsExplored: Set<String> = []
        var bfsOptimalPath = [SCNNode]()
        var nodeParentRecord = [SCNNode : SCNNode]()
        
        bfsFrontier.append(start.name!)
        nodeParentRecord[start] = nil
        
        outerLoop: while !bfsFrontier.isEmpty
        {
            let currID = bfsFrontier.removeFirst()
            bfsExplored.insert(currID)
            
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
                        if (!bfsExplored.contains(neighborNode.name!) && (!bfsFrontier.contains(currID)))
                        {
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                            if neighborNode.name! == "Goal"
                            {
                                bfsOptimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                                break outerLoop
                            }
                            bfsFrontier.append(neighborNode.name!)
                        }
                    }
                }
            }
        }
        // do something with optimal path
        print("BFS Optimal Path:")
        var goalFound = false
        for optNode in bfsOptimalPath
        {
            print(optNode.name!)
            if optNode.name! == "Goal"
            {
                goalFound = true
            }
        }
        
        if goalFound
        {
            mGrid.createPath(optimalPath: bfsOptimalPath, algorithm: "Breadth-First")
        }
        
        return (bfsFrontier, bfsExplored, bfsOptimalPath)
    }
    
    
    public func run_Dijkstra() -> (Heap<(Float, String)>, [String], [SCNNode])
    {
        print("RUNNING DIJKSTRA:")
        let gridRowRange = 0...pointCloudArray.count-1
        let gridColRange = 0...pointCloudArray[0].count-1
        
        let pathCost: Float = 0.0
        let startNodeInfo = (pathCost,start.name!)
        var dijkstraFrontier = Heap<(Float, String)>(sort: <)
        var dijkstraExplored = [String]()
        var dijkstraOptimalPath = [SCNNode]()
        var nodeParentRecord = [SCNNode : SCNNode]() // // keep track of nodes and their parent nodes
        dijkstraFrontier.insert(startNodeInfo)
        nodeParentRecord[start] = nil
        
        while !dijkstraFrontier.isEmpty
        {
            let (currPathCost, currID) = dijkstraFrontier.remove()!
            // check to see if goal node has been popped
            if currID == "Goal"
            {
                dijkstraOptimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                break
            }
            dijkstraExplored.append(currID)
            
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
                        
                        if (!dijkstraExplored.contains(neighborNode.name!)) && (!dijkstraFrontier.nodes.contains { $0.1 == neighborNode.name! })
                        {
                            dijkstraFrontier.insert(neighborNodeInfo)
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                        }
                        else if (dijkstraFrontier.nodes.contains { $0.1 == neighborNode.name! })
                        {
                            // find and compare current node cost with node cost on frontier
                            let frontierIndex = dijkstraFrontier.nodes.firstIndex{$0.1 == neighborNode.name!}!
                            let (frontierPathcost,_) = dijkstraFrontier.nodes[frontierIndex]
                            
                            if (frontierPathcost > neighborTotalPathCost)
                            {
                                dijkstraFrontier.replace(index: frontierIndex, value: neighborNodeInfo)
                                nodeParentRecord[neighborNode] = currNode
                            }
                        }
                        
                    }
                }
            }
        }
        // do something with optimal path
        print("Dijkstra's Optimal Path:")
        var goalFound = false
        for optNode in dijkstraOptimalPath
        {
            print(optNode.name!)
            if optNode.name! == "Goal"
            {
                goalFound = true
            }
        }
        
        if goalFound
        {
            mGrid.createPath(optimalPath: dijkstraOptimalPath, algorithm: "Dijkstra's")
        }
            
        return (dijkstraFrontier, dijkstraExplored, dijkstraOptimalPath)
    }
    
    public func run_Astar(heuristic: String) -> (Heap<(Float, Float, Float, String)>, [String], [SCNNode])
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
        var aStarFrontier = Heap<(Float, Float, Float, String)>(sort: <)
        var aStarExplored = [String]()
        var aStarOptimalPath = [SCNNode]()
        var nodeParentRecord = [SCNNode : SCNNode]() // // keep track of nodes and their parent nodes
        aStarFrontier.insert(startNodeInfo)
        nodeParentRecord[start] = nil
        
        // F-Cost = (G-Cost + H-Cost) where G is pathCost and H is heuristic cost
        // node: (priority,heuristicCost,pathCost,nodeID)
        while !aStarFrontier.isEmpty
        {
            let (_, _, currPathCost, currID) = aStarFrontier.remove()!
            // check to see if goal node has been popped
            if currID == "Goal"
            {
                aStarOptimalPath = backtracePath(startNode: start, goalNode: goal, nodeParentRecord: nodeParentRecord)
                break
            }
            aStarExplored.append(currID)
            
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
                        
                        if (!aStarExplored.contains(neighborNode.name!)) && (!aStarFrontier.nodes.contains { $0.3 == neighborNode.name! })
                        {
                            aStarFrontier.insert(neighborNodeInfo)
                            nodeParentRecord[neighborNode] = currNode // add neighbor and its parent to path
                        }
                        else if (aStarFrontier.nodes.contains { $0.3 == neighborNode.name! })
                        {
                            // find and compare current node cost with node cost on frontier
                            let frontierIndex = aStarFrontier.nodes.firstIndex{$0.3 == neighborNode.name!}!
                            let (frontierFcost,_,_,_) = aStarFrontier.nodes[frontierIndex]
                            
                            if (frontierFcost > neighborFcost)
                            {
                                aStarFrontier.replace(index: frontierIndex, value: neighborNodeInfo)
                                nodeParentRecord[neighborNode] = currNode
                            }
                        }
                    }
                }
            }
        }
        // do something with optimal path
        print("A* Optimal Path:")
        var goalFound = false
        for optNode in aStarOptimalPath
        {
            print(optNode.name!)
            if optNode.name! == "Goal"
            {
                goalFound = true
            }
        }
        
        if goalFound
        {
            mGrid.createPath(optimalPath: aStarOptimalPath, algorithm: "A*")
            mGrid.animateObjectAlongPath(optimalPath: aStarOptimalPath)
        }
        
        return (aStarFrontier, aStarExplored, aStarOptimalPath)
    }
}
