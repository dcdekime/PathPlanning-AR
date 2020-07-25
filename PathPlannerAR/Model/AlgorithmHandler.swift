//
//  AlgorithmHandler.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/9/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

struct AlgorithmHandler
{
    let mGrid : Grid
    let mAlgorithm : String
    let mHeuristic : String
    var mPathModel : PathModel
    
    
    init(currGrid: Grid, algorithm: String, heuristic: String = "None", pathModel: PathModel)
    {
        mGrid = currGrid
        mAlgorithm = algorithm
        mHeuristic = heuristic
        mPathModel = pathModel
    }
    
    mutating func runSelectedAlgorithm() -> PathModel
    {
        let algoSimulator = AlgorithmSimulator(currGrid: mGrid)
        //let algoStepper = AlgorithmStepper(currGrid: mGrid, heuristic: heuristic)

        switch mAlgorithm
        {
        case "Breadth-First":
            let (bfsFrontier, bfsExplored, bfsOptimalPath) = algoSimulator.run_BFS()
            mPathModel.setPath(optPath: bfsOptimalPath)
            mPathModel.setExploredLength(exploredLength: bfsExplored.count)
            mPathModel.setFrontierLength(frontierLength: bfsFrontier.count)
        case "Dijkstra's":
            let (dijkstraFrontier, dijkstraExplored, dijkstraOptimalPath) = algoSimulator.run_Dijkstra()
            mPathModel.setPath(optPath: dijkstraOptimalPath)
            mPathModel.setExploredLength(exploredLength: dijkstraExplored.count)
            mPathModel.setFrontierLength(frontierLength: dijkstraFrontier.count)
        case "A*":
            let (aStarFrontier, aStarExplored, aStarOptimalPath) = algoSimulator.run_Astar(heuristic: mHeuristic)
            mPathModel.setPath(optPath: aStarOptimalPath)
            mPathModel.setExploredLength(exploredLength: aStarExplored.count)
            mPathModel.setFrontierLength(frontierLength: aStarFrontier.count)
            
        default:
            let (aStarFrontier, aStarExplored, aStarOptimalPath) = algoSimulator.run_Astar(heuristic: mHeuristic)
            mPathModel.setPath(optPath: aStarOptimalPath)
            mPathModel.setExploredLength(exploredLength: aStarExplored.count)
            mPathModel.setFrontierLength(frontierLength: aStarFrontier.count)
        }
        
        return mPathModel
    }
}
