//
//  PathModel.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/16/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import Foundation
import ARKit

struct PathModel
{
    private var mOptimalPath : [SCNNode]
    private var mExploredLength : Int
    private var mFrontierLength : Int
    //private var mPathInfo : String
    
    init()
    {
        mOptimalPath = [SCNNode]()
        mExploredLength = 0
        mFrontierLength = 0
    }
    
    // setter functions
    mutating func setPath(optPath: [SCNNode])
    {
        mOptimalPath = optPath
    }
    mutating func setExploredLength(exploredLength: Int)
    {
        mExploredLength = exploredLength
    }
    mutating func setFrontierLength(frontierLength : Int)
    {
        mFrontierLength = frontierLength
    }
    
    // getter functions
    func getPath() -> [SCNNode]
    {
        return mOptimalPath
    }
    func getExploredLength() -> Int
    {
        return mExploredLength
    }
    func getFrontierLength() -> Int
    {
        return mFrontierLength
    }
}
