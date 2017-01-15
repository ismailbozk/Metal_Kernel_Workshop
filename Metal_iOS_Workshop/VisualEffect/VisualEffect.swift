//
//  VisualEffect.swift
//  Metal_iOS_Workshop
//
//  Created by Ismail Bozkurt on 15/01/2017.
//  Copyright © 2017 MTT. All rights reserved.
//

import Foundation
import UIKit

protocol SaturationEffect {
    
    func saturate(image: UIImage, saturationFactor: Float)
    
    var saturatedImage: UIImage? { get }
}
