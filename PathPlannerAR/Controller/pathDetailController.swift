//
//  pathDetailController.swift
//  PathPlannerAR
//
//  Created by David DeKime on 7/19/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import UIKit

class pathDetailController: UIViewController
{
    @IBOutlet weak var bfsPathLength: UILabel!
    @IBOutlet weak var dijkstraPathLength: UILabel!
    @IBOutlet weak var aStarPathLength: UILabel!
    
    @IBOutlet weak var bfsExploredNodes: UILabel!
    @IBOutlet weak var dijkstraExploredNodes: UILabel!
    @IBOutlet weak var aStarExploredNodes: UILabel!
    
    @IBOutlet weak var bfsFrontierLength: UILabel!
    @IBOutlet weak var dijkstraFrontierLength: UILabel!
    @IBOutlet weak var aStarFrontierLength: UILabel!
    @IBOutlet weak var backButtonDesign: UIButton!
    
    var bfsPL : String?
    var bfsNE : String?
    var bfsFL : String?
    var dijkstraPL : String?
    var dijkstraNE : String?
    var dijkstraFL : String?
    var aStarPL : String?
    var aStarNE : String?
    var aStarFL : String?
    
    @IBOutlet weak var bfsTextView: UITextView!
    @IBOutlet weak var dijkstraTextView: UITextView!
    @IBOutlet weak var aStarTextView: UITextView!
    
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        bfsPathLength.text = bfsPL
        bfsExploredNodes.text = bfsNE
        bfsFrontierLength.text = bfsFL
        
        dijkstraPathLength.text = dijkstraPL
        dijkstraExploredNodes.text = dijkstraNE
        dijkstraFrontierLength.text = dijkstraFL
        
        aStarPathLength.text = aStarPL
        aStarExploredNodes.text = aStarNE
        aStarFrontierLength.text = aStarFL
        
        
        
        bfsTextView.text = "Breadth-first search is an instance of the general graph-search algorithm and find the path between two points using a FIFO (First In First Out) queue data structure as the frontier. Nodes are explored in the order in which they were enqueued on the frontier. The search terminates when one of the current node's neighbors  is equal to the goal. \n \n Pseudocode: \n \n Append start node to frontier \n While frontier NOT empty: \n   currentNode = Frontier.pop(0) \n   If currentNode NOT in ExploredList \n   Add currentNode to ExploredList \n        For each neighbor of current node: \n            If neighbor NOT in ExploredList or Frontier \n                 If neighbor = Goal \n                       return Path \n                 Frontier.append(neighbor)"
        
        
        dijkstraTextView.text = "Dijkstra's algorithm finds the shortest path between two points, but rather than using a Frontier with a FIFO queue like BFS, a priority queue is used which prioritizes nodes with lowest path cost. The search terminates when the current node that pops off of the frontier is equal to the goal node. \n \n Pseudocode: \n \n Append start node to frontier with 0 pathCost \n While frontier NOT empty: \n    currentNode = Frontier.pop(0) \n    If currentNode = Goal \n        return Path \n    Add currentNode to ExploredList \n    For each neighbor of current node: \n        Update neighborNode path cost \n        If neighbor NOT in ExploredList or Frontier \n            Frontier.append(neighborNode) \n        Else If neighbor IN Frontier \n            If neighborNode pathCost < Frontier pathCost \n                Replace Frontier node with neighborNode"
        
        aStarTextView.text = "The A* algorithm finds the shortest path between two points, and uses a Frontier made up of a priority queue similar to Dijkstra's algorithm. However, A* doesn't simply prioritize minimum path cost. It uses the combination of a heuristic value as well as the path cost to prioritize nodes to be searched. The heuristic can vary, but is often the calculated distance from a current node to the goal. Common heuristics for A* are Euclidean distance and Manhattan distance. The A* priority queue prioritizes F-cost where F = G + H. G is the pathCost and H is the heuristic value of a given node. Similar to Dijkstra's algorithm, the search terminates when the current node that pops off of the frontier is equal to the goal node. \n \n Pseudocode: \n \n Append start node to frontier with 0 pathCost \n While frontier NOT empty: \n    currentNode = Frontier.pop(0) \n    If currentNode = Goal \n        return Path \n    Add currentNode to ExploredList \n    For each neighbor of current node: \n        Update neighborNode F-cost \n        If neighbor NOT in ExploredList or Frontier \n            Frontier.append(neighborNode) \n        Else If neighbor IN Frontier \n            If neighborNode F-cost < Frontier F-cost \n                Replace Frontier node with neighborNode"
    }
}
