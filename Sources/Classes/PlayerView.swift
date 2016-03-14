//
//  PlayerVideoViewController.swift
//  PlayerVideo
//
//  Created by David Alejandro on 2/17/16.
//  Copyright © 2016 David Alejandro. All rights reserved.
//

import UIKit
import AVFoundation.AVPlayer


public typealias PlayerViewStatus = AVPlayerStatus
public typealias PlayerViewItemStatus = AVPlayerItemStatus
public typealias PlayerviewTimeRange = CMTimeRange

public protocol PlayerViewDelegate: class
{
    func playerVideo(player: PlayerView, statusPlayer: PlayerViewStatus, error: NSError?)
    func playerVideo(player: PlayerView, statusItemPlayer: PlayerViewItemStatus, error: NSError?)
    func playerVideo(player: PlayerView, loadedTimeRanges: [PlayerviewTimeRange])
    func playerVideo(player: PlayerView, duration: Double)
    func playerVideo(player: PlayerView, currentTime: Double)
    func playerVideo(player: PlayerView, rate: Float)
    func playerVideo(player: PlayerView, playerFinished: Bool)
}

// make protocol optional
public extension PlayerViewDelegate
{
    func playerVideo(player: PlayerView, statusPlayer: PlayerViewStatus, error: NSError?)
    {
    }
    func playerVideo(player: PlayerView, statusItemPlayer: PlayerViewItemStatus, error: NSError?)
    {
    }
    func playerVideo(player: PlayerView, loadedTimeRanges: [PlayerviewTimeRange])
    {
    }
    func playerVideo(player: PlayerView, duration: Double)
    {
    }
    func playerVideo(player: PlayerView, currentTime: Double)
    {
    }
    func playerVideo(player: PlayerView, rate: Float)
    {
    }
    func playerVideo(player: PlayerView, playerFinished: Bool)
    {
    }
}


public enum PlayerViewFillMode
{
    case ResizeAspect
    case ResizeAspectFill
    case Resize
    
    init?(videoGravity: String)
    {
        switch videoGravity
        {
            case AVLayerVideoGravityResizeAspect:
                self = .ResizeAspect
            case AVLayerVideoGravityResizeAspectFill:
                self = .ResizeAspectFill
            case AVLayerVideoGravityResize:
                self = .Resize
            default:
                return nil
        }
    }
    
    var AVLayerVideoGravity:String
    {
        get
        {
            switch self
            {
                case .ResizeAspect:
                    return AVLayerVideoGravityResizeAspect
                case .ResizeAspectFill:
                    return AVLayerVideoGravityResizeAspectFill
                case .Resize:
                    return AVLayerVideoGravityResize
            }
        }
    }
}

/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
@objc public class PlayerView: UIView
{
    private var playerLayer: AVPlayerLayer
    {
        return self.layer as! AVPlayerLayer
    }
    
    private var timeObserverToken: AnyObject!
    
    //MARK: - Public Variables
    public weak var delegate: PlayerViewDelegate!
    
    public var player: AVPlayer!
    {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }

    public var fillMode: PlayerViewFillMode!
    {
        didSet { playerLayer.videoGravity = fillMode.AVLayerVideoGravity }
    }
    
    public var currentTime: Double
    {
        get
        {
            guard let player = self.player else {
                return 0
            }
            return CMTimeGetSeconds(player.currentTime())
        }
        set
        {
            guard let timescale = player?.currentItem?.duration.timescale else {
                return
            }
            let newTime = CMTimeMakeWithSeconds(newValue, timescale)
            player!.seekToTime(newTime,toleranceBefore: kCMTimeZero,toleranceAfter: kCMTimeZero)
        }
    }
    
    public var interval = CMTimeMake(1, 60)
    {
        didSet
        {
            guard let player = self.player else {
                return
            }
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) { [weak self] time-> Void in
                if let mySelf = self {
                    self?.delegate?.playerVideo(mySelf, currentTime: mySelf.currentTime)
                }
            }
        }
    }
    
    public var rate: Float
    {
        get
        {
            guard let player = self.player else {
                return 0
            }
            return player.rate
        }
        
        set
        {
            player?.rate = newValue
        }
    }
    
    // MARK: public Functions
    
    public func play()
    {
        beginTimeObserve()
        player?.play()
    }
    
    public func pause()
    {
        player?.pause()
        endTimeObserve()
    }
    
    public func stop()
    {
        currentTime = 0
        pause()
    }
    
    public func availableDuration() -> CMTimeRange
    {
        if let range = self.player?.currentItem?.loadedTimeRanges.first
        {
            return range.CMTimeRangeValue
        }
        return kCMTimeRangeZero
    }
    
    public func screenshot() throws -> UIImage?
    {
        guard let player = player , let asset = player.currentItem?.asset else {
            return nil
        }
        let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        guard let time = player.currentItem?.currentTime() else {
            return nil
        }
        let ref = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
        let viewImage: UIImage = UIImage(CGImage: ref)
        return viewImage
    }
    
    public var url: NSURL!
    {
        didSet
        {
            unLoad()
            load()
        }
    }
    
    func unLoad()
    {
        if player != nil
        {
            stop()
            
            player.removeObserver(self, forKeyPath: "status", context: &statusContext)
            player.removeObserver(self, forKeyPath: "rate", context: &rateContext)
            
            if let playerItem = player.currentItem
            {
                playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: &loadedContext)
                playerItem.removeObserver(self, forKeyPath: "duration", context: &durationContext)
                playerItem.removeObserver(self, forKeyPath: "status", context: &statusItemContext)
                NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
            }
            self.player = nil
        }
    }
    
    func load()
    {
        if url == nil
        {
            return
        }
        
        self.player = AVPlayer(URL: url)
        player.actionAtItemEnd = .None
        
        let playerItem = player.currentItem!
        
        player.addObserver(self, forKeyPath: "status", options: [.New], context: &statusContext)
        player.addObserver(self, forKeyPath: "rate", options: [.New], context: &rateContext)
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: [], context: &loadedContext)
        playerItem.addObserver(self, forKeyPath: "duration", options: [], context: &durationContext)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: &statusItemContext)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidPlayToEndTime:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
    }
    
    func beginTimeObserve()
    {
        if timeObserverToken == nil
        {
            timeObserverToken = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) { [weak self] time-> Void in
                if let mySelf = self {
                    self?.delegate?.playerVideo(mySelf, currentTime: mySelf.currentTime)
                }
            }
        }
    }
    
    func endTimeObserve()
    {
        if timeObserverToken != nil
        {
            player.removeTimeObserver(timeObserverToken)
            timeObserverToken = nil
        }
    }
    
    
    // MARK: public object lifecycle view
    
    override public class func layerClass() -> AnyClass
    {
        return AVPlayerLayer.self
    }
    
    public convenience init()
    {
        self.init(frame: CGRect.zero)
        self.fillMode = .ResizeAspect
    }
    
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.fillMode = .ResizeAspect
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.fillMode = .ResizeAspect
    }
    
    deinit
    {
        unLoad()
    }
    
    // MARK: private variables for context KVO
    
    private var statusContext = true
    private var statusItemContext = true
    private var loadedContext = true
    private var durationContext = true
    private var currentTimeContext = true
    private var rateContext = true
    
    public func playerItemDidPlayToEndTime(aNotification: NSNotification)
    {
        stop()
        self.delegate?.playerVideo(self, playerFinished: true)
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if context == &statusContext
        {
            guard let avPlayer = player else {
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
                return
            }
            self.delegate?.playerVideo(self, statusPlayer: avPlayer.status, error: avPlayer.error)
            
            
        } else if context == &loadedContext
        {
            let playerItem = player?.currentItem
            
            guard let times = playerItem?.loadedTimeRanges else {
                return
            }
            
            let values = times.map({ $0.CMTimeRangeValue})
            self.delegate?.playerVideo(self, loadedTimeRanges: values)
            
        } else if context == &durationContext
        {
            if let currentItem = player?.currentItem {
                self.delegate?.playerVideo(self, duration: currentItem.duration.seconds)
                
            }
            
        } else if context == &statusItemContext
        {
            //status of item has changed
            if let currentItem = player?.currentItem
            {
                self.delegate?.playerVideo(self, statusItemPlayer: currentItem.status, error: currentItem.error)
            }
            
        } else if context == &rateContext
        {
            guard let newRateNumber = (change?[NSKeyValueChangeNewKey] as? NSNumber) else{
                return
            }
            let newRate = newRateNumber.floatValue
            self.delegate?.playerVideo(self, rate: newRate)
            
        } else
        {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
