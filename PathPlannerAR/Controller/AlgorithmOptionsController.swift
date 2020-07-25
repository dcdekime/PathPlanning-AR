//
//  AlgorithmOptionsController.swift
//  PathPlannerAR
//
//  Created by David DeKime on 6/27/20.
//  Copyright © 2020 David DeKime. All rights reserved.
//

import UIKit

class AlgorithmOptionsController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectAlgoLabel: UILabel!
    @IBOutlet weak var selectHeuristicLabel: UILabel!
    var algorithmPickerData: [String] = [String]()
    var heuristicPickerData: [String] = [String]()
    var selectedAlgorithm = ""
    var selectedHeuristic = ""
    let arVCObject = ViewController()
    
    @IBOutlet weak var AlgorithmPicker: UIPickerView!
    @IBOutlet weak var HeuristicPicker: UIPickerView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        titleLabel.textColor = UIColor.black

        selectAlgoLabel.textColor = UIColor.white
        selectAlgoLabel.layer.cornerRadius = 6
        selectHeuristicLabel.textColor = UIColor.white
        selectHeuristicLabel.layer.cornerRadius = 6
        
        AlgorithmPicker.dataSource = self
        AlgorithmPicker.delegate = self
        
        HeuristicPicker.dataSource = self
        HeuristicPicker.delegate = self
        
        AlgorithmPicker.setValue(UIColor.white, forKeyPath: "textColor")
        AlgorithmPicker.layer.borderColor = UIColor.black.cgColor
        AlgorithmPicker.layer.borderWidth = 3
        AlgorithmPicker.layer.cornerRadius = 10
        
        HeuristicPicker.setValue(UIColor.white, forKeyPath: "textColor")
        HeuristicPicker.layer.borderColor = UIColor.black.cgColor
        HeuristicPicker.layer.borderWidth = 3
        HeuristicPicker.layer.cornerRadius = 10
        
        algorithmPickerData = ["Breadth-First", "Dijkstra's", "A*"]
        heuristicPickerData = ["None","Euclidean Distance", "Manhattan Distance"]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
           if pickerView == AlgorithmPicker {
             return algorithmPickerData.count

         } else if pickerView == HeuristicPicker{
              return heuristicPickerData.count
         }

         return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerView == AlgorithmPicker
        {
            return algorithmPickerData[row]
        }
        else if pickerView == HeuristicPicker
        {
            return heuristicPickerData[row]
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if pickerView == AlgorithmPicker
        {
            selectedAlgorithm = algorithmPickerData[row]
        }
        else if pickerView == HeuristicPicker
        {
            selectedHeuristic = heuristicPickerData[row]
        }
    }

    
    @IBAction func transferToARScreen(_ sender: UIButton)
    {
        performSegue(withIdentifier: "toAR", sender: self)
    }
    
    // gets called just before segue occurs
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "toAR"
        {
            // initialize object of ResultViewController class and set bmi value so that the proper value gets set before second screen loads
            let destinationVC = segue.destination as! ViewController
            destinationVC.algorithmSelected = selectedAlgorithm
            destinationVC.heuristicSelected = selectedHeuristic

        }
    }
}
