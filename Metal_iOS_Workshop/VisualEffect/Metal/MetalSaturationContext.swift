//
//  MetalSaturationContext.swift
//  Metal_iOS_Workshop
//
//  Created by Ismail Bozkurt on 15/01/2017.
//  Copyright © 2017 MTT. All rights reserved.
//

import UIKit

enum MetalSaturationContextError: Error {
    case initialize
}

class MetalSaturationContext: MetalContext {
    
    var device: MTLDevice
    var library: MTLLibrary
    var commandQueue: MTLCommandQueue
    
    /// Holds the function definitation and very constly to initialize. However, it is thread safe, so reuse encouraged. This is where the kernel c++ function attached to the pipeline.
    var metalComputePipelineState: MTLComputePipelineState
    
    init() throws {
        self.device = MTLCreateSystemDefaultDevice()!
        self.library = (device.newDefaultLibrary())!
        self.commandQueue = device.makeCommandQueue()
        
        guard let saturationKernelFunction : MTLFunction = library.makeFunction(name: "adjust_saturation") else {
            throw MetalSaturationContextError.initialize
        }
        
        do{
            self.metalComputePipelineState = try device.makeComputePipelineState(function: saturationKernelFunction)
        } catch _ {
            throw MetalSaturationContextError.initialize
        }
        
    }
}
