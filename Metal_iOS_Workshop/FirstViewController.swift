//
//  FirstViewController.swift
//  Metal_iOS_Workshop
//
//  Created by Ismail Bozkurt on 15/01/2017.
//  Copyright © 2017 MTT. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    let image = UIImage(named: "mandrill")!
    @IBOutlet weak var topImageView: UIImageView!
    @IBOutlet weak var bottomImageView: UIImageView!
    
    var saturationEffect: MetalVisualEffect!
    
    var operationQueue: OperationQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loadingOperation = contentLoadingOperation()
        let intialSaturationOperation = saturationOperation(image: image, saturationFactor: 0.3)
        intialSaturationOperation.addDependency(loadingOperation)
        
        operationQueue.addOperation(loadingOperation)
        operationQueue.addOperation(intialSaturationOperation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.topImageView.image = image
    }
    
    // Mark - Slider
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        let value = slider.value
        let operation = saturationOperation(image: image, saturationFactor: value)
        operationQueue.addOperation(operation)
    }
        
    // Mark - Operations
    
    func contentLoadingOperation() -> Operation {
        let operation = BlockOperation { [unowned self] in
            let saturationContext = try! MetalSaturationContext()
            self.saturationEffect = MetalVisualEffect(context: saturationContext)
        }
        
        operation.queuePriority = .veryHigh
        
        return operation
    }
    
    func saturationOperation(image: UIImage, saturationFactor: Float) -> Operation {
        let operation = BlockOperation { [unowned self] in
            self.saturationEffect.saturate(image: image, saturationFactor: saturationFactor)
        }
        
        operation.completionBlock = { [unowned self] in
            DispatchQueue.main.async {
                self.bottomImageView.image = self.saturationEffect.saturatedImage
            }
        }
        
        operation.queuePriority = .veryHigh
        
        return operation
    }
}

