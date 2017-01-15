//
//  MetalContext.swift
//  Metal_iOS_Workshop
//
//  Created by Ismail Bozkurt on 15/01/2017.
//  Copyright © 2017 MTT. All rights reserved.
//

import UIKit
import Metal


protocol MetalContext {
    var device: MTLDevice { get }
    var library: MTLLibrary { get }
    var commandQueue: MTLCommandQueue { get }
}
