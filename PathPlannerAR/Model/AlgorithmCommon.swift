//
//  AlgorithmCommon.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/9/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class AlgorithmCommon
{
    public func calculateEuclideanDistance(currentNode: SCNNode, nextNode: SCNNode) -> Float
    {
        // XZ plane
        let absDiffX = currentNode.position.x - nextNode.position.x
        let absDiffZ = currentNode.position.z - nextNode.position.z
        let straightLineDistance = sqrtf(pow(absDiffX,2) + pow(absDiffZ,2))
        
        return straightLineDistance
    }
    
    public func getCurrentNodeIndex(pointCloudArray: [[SCNNode]], nodeID: String) -> (Int,Int)
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
    
    public func backtracePath(startNode:SCNNode, goalNode:SCNNode, nodeParentRecord:[SCNNode:SCNNode]) -> [SCNNode]
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
    
}
