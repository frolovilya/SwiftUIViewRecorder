import AVFoundation
import UIKit
import Combine
import CoreMedia

extension Array where Element == UIImage {
    
    private func makeUniqueTempVideoURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = ProcessInfo.processInfo.globallyUniqueString
        return tempDir.appendingPathComponent(fileName).appendingPathExtension("mov")
    }
        
    private var frameSize: CGSize {
        CGSize(width: (first?.size.width ?? 0) * UIScreen.main.scale,
               height: (first?.size.height ?? 0) * UIScreen.main.scale)
    }
    
    private func videoSettings(codecType: AVVideoCodecType) -> [String: Any] {
        return [
            AVVideoCodecKey: codecType,
            AVVideoWidthKey: frameSize.width,
            AVVideoHeightKey: frameSize.height
        ]
    }
    
    private var pixelAdaptorAttributes: [String: Any] {
        [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCMPixelFormat_32BGRA)
        ]
    }
    
    /**
     Convert array of `UIImage`s to QuickTime video.
     
     This method runs on a Main queue by default.
     Video generation is a time consuming process, subscribe on a different background queue for better performance.
     
     Video file is generated in a temporary directory. It's a calling code responsibility to unlink the file once not needed.
     
     - Precondition: `framesPerSecond` must be greater than 0
     
     - Parameter framesPerSecond: video FPS. How many samples are presented per second.
     - Parameter codecType: video codec to use. By default is H264. See `AVVideoCodecType` for other available options.
     
     - Returns: Future URL of a generated video file or Error
     */
    func toVideo(framesPerSecond: Double,
                 codecType: AVVideoCodecType = .h264) -> Future<URL?, Error> {
        print("Generating video framesPerSecond=\(framesPerSecond), codecType=\(codecType.rawValue)")
        
        return Future<URL?, Error> { promise in
            guard self.count > 0 else {
                promise(.failure(UIImagesToVideoError.noFrames))
                return
            }
            
            guard framesPerSecond > 0 else {
                promise(.failure(UIImagesToVideoError.invalidFramesPerSecond))
                return
            }
            
            let url = self.makeUniqueTempVideoURL()
            
            let writer: AVAssetWriter
            do {
                writer = try AVAssetWriter(outputURL: url, fileType: .mov)
            } catch {
                promise(.failure(error))
                return
            }
                        
            let input = AVAssetWriterInput(mediaType: .video,
                                           outputSettings: self.videoSettings(codecType: codecType))
                                    
            if (writer.canAdd(input)) {
                writer.add(input)
            } else {
                promise(.failure(UIImagesToVideoError.internalError))
                return
            }
            
            let pixelAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input,
                                                                    sourcePixelBufferAttributes: pixelAdaptorAttributes)
            
            writer.startWriting()
            writer.startSession(atSourceTime: CMTime.zero)
            
            var frameIndex: Int = 0
            while frameIndex < self.count {
                if (input.isReadyForMoreMediaData) {
                    if let buffer = self[frameIndex].toSampleBuffer(frameIndex: frameIndex,
                                                                    framesPerSecond: framesPerSecond) {
                        pixelAdaptor.append(CMSampleBufferGetImageBuffer(buffer)!,
                                            withPresentationTime: CMSampleBufferGetOutputPresentationTimeStamp(buffer))
                    }
                    
                    frameIndex += 1
                }
            }
        
            writer.finishWriting {
                switch writer.status {
                case .completed:
                    print("Successfully finished writing video \(url)")
                    promise(.success(url))
                    break
                default:
                    let error = writer.error ?? UIImagesToVideoError.internalError
                    print("Finished writing video without success \(error)")
                    promise(.failure(error))
                }
            }
        }
    }
    
}
