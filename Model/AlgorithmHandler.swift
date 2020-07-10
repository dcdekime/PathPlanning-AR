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
    
    init(currGrid: Grid, algorithm: String, heuristic: String = "None")
    {
        mGrid = currGrid
        mAlgorithm = algorithm
        mHeuristic = heuristic
    }
    
    func runSelectedAlgorithm()
    {
        let algoSimulator = AlgorithmSimulator(currGrid: mGrid)
        //let algoStepper = AlgorithmStepper(currGrid: mGrid, heuristic: heuristic)

        switch mAlgorithm
        {
        case "Breadth-First":
            algoSimulator.run_BFS()
        case "Dijkstra's":
            algoSimulator.run_Dijkstra()
        case "A*":
            algoSimulator.run_Astar(heuristic: mHeuristic)
            
        default:
            algoSimulator.run_Astar(heuristic: mHeuristic)
        }
    }
}
