//
//  MetalVisualEffect.swift
//  Metal_iOS_Workshop
//
//  Created by Ismail Bozkurt on 15/01/2017.
//  Copyright © 2017 MTT. All rights reserved.
//

import UIKit

class MetalVisualEffect: SaturationEffect {
    
    private let context: MetalSaturationContext
    init(context: MetalSaturationContext) {
        self.context = context
    }
    
    // Mark - <SaturationEffect>
    var saturatedImage: UIImage?
    func saturate(image: UIImage, saturationFactor: Float) {
        // STEP 1: shader configuration
        let commandBuffer = self.context.commandQueue.makeCommandBuffer() // new page for new operation
        
        // this guys will be the one submits and executes the kernel function
        let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
        
        // use pre initialized pipeline in here. This way it is faster
        computeCommandEncoder.setComputePipelineState(context.metalComputePipelineState);
        
        // STEP 2: Pass the data to GPU

        // Step 2.1: pass image as input. It is going to be read only
        let imageTextureBuffer = textureFromImage(image, forDevice: context.device)

        // check the 'at' index in kernel shader. They must match.
        computeCommandEncoder.setTexture(imageTextureBuffer, at: 0);
        
        // Step 2.2: pass saturation factor as float
        // compute the how much data is going to trasfered from CPU to GPU.
        let inputByteLength = MemoryLayout<Float>.size;
        var saturationFactorCopy = Float(saturationFactor)
        
        let inVectorBuffer = context.device.makeBuffer(bytes: &saturationFactorCopy, length: inputByteLength, options: [])// some buffers can be shared between CPU and GPU. But it is an advanced topic.
        
        //again pay attention to indices. Offset is 0.
        computeCommandEncoder.setBuffer(inVectorBuffer, offset: 0, at: 0);
        
        // STEP 3: Setup output image
        
        let outputImageTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm,// Important: must match with your image presentation
            width: Int(image.size.width),
            height: Int(image.size.height),
            mipmapped: false)
        
        let outputImageTexture = self.context.device.makeTexture(descriptor: outputImageTextureDescriptor)
        
        // it is the second texture in the texture buffer
        computeCommandEncoder.setTexture(outputImageTexture, at: 1)

        
        // STEP 4: prepare thread groups. 
        // Every device has different thread width. i.e. iPhone 6 has 512.
        
        let threadGroupCount = MTLSizeMake(8, 8, 1);
        let threadGroup = MTLSizeMake(Int(image.size.width) / threadGroupCount.width,
                                      Int(image.size.height) / threadGroupCount.height,
                                      1)

        computeCommandEncoder.dispatchThreadgroups(threadGroup, threadsPerThreadgroup: threadGroupCount)

        // STEP 4: Commit and pack everthing, ready to go
        computeCommandEncoder.endEncoding()

        // Optional message way with a completion block
//        commandBuffer.addCompletedHandler({ (commandBuffer : MTLCommandBuffer) -> Void in
//        });
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        self.saturatedImage = imageFromTexture(outputImageTexture)
    }
}


// Mark - Private Helpers

func imageFromTexture(_ texture: MTLTexture) -> UIImage {
    // The total number of bytes of the texture
    let imageByteCount = texture.width * texture.height * bytesPerPixel
    
    // The number of bytes for each image row
    let bytesPerRow = texture.width * bytesPerPixel
    
    // An empty buffer that will contain the image
    var src = [UInt8](repeating: 0, count: Int(imageByteCount))
    
    // Gets the bytes from the texture
    let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
    texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
    
    // Creates an image context
    let context = CGContext(data: &src, width: texture.width, height: texture.height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
    
    // Creates the image from the graphics context
    let dstImage = context?.makeImage()
    
    // Creates the final UIImage
    return UIImage(cgImage: dstImage!, scale: 0.0, orientation: .up)
}

fileprivate let bytesPerPixel = 4
fileprivate let bitsPerComponent = 8
fileprivate let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
fileprivate let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)


fileprivate func textureFromImage(_ image: UIImage, forDevice device: MTLDevice) -> MTLTexture? {
    let coreImage: CGImage = image.cgImage!
    
    // Create a suitable bitmap context for extracting the bits of the image
    let width = coreImage.width
    let height = coreImage.height
   
    let bytesPerRow = bytesPerPixel * width
    
    var rawData = [UInt8](repeating: 0, count: Int(width * height * 4))
    guard let bitmapContext = CGContext.init(data: &rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: UInt32(bitmapInfo.rawValue)) else {
        return nil
    }
    
    // Flip the context so the positive Y axis points down
    // Not necessary
//    bitmapContext.translateBy(x: 0, y: CGFloat(height))
//    bitmapContext.scaleBy(x: 1, y: -1)

    bitmapContext.draw(coreImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    
    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm,// Important: must match with your image presentation
                                                                      width: width,
                                                                      height: height,
                                                                      mipmapped: false)
    
    let texture = device.makeTexture(descriptor: textureDescriptor) // MAGICAL function
    let region = MTLRegionMake2D(0, 0, width, height)
    texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: bytesPerRow)
    
    return texture
}

