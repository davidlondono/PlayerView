//
//  PlayerVideoViewController.swift
//  PlayerVideo
//
//  Created by David Alejandro on 2/17/16.
//  Copyright © 2016 David Alejandro. All rights reserved.
//

import UIKit
import AVFoundation.AVPlayer

private extension Selector {
    static let playerItemDidPlayToEndTime = #selector(PlayerView.playerItemDidPlayToEndTime(_:))
}

public extension PVTimeRange{
    static let zero = kCMTimeRangeZero
}

public typealias PVStatus = AVPlayerStatus
public typealias PVItemStatus = AVPlayerItemStatus
public typealias PVTimeRange = CMTimeRange
public typealias PVPlayer = AVQueuePlayer
public typealias PVPlayerItem = AVPlayerItem

public protocol PlayerViewDelegate: class {
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: NSError?)
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: NSError?)
    func playerVideo(player: PlayerView, loadedTimeRanges: [PVTimeRange])
    func playerVideo(player: PlayerView, duration: Double)
    func playerVideo(player: PlayerView, currentTime: Double)
    func playerVideo(player: PlayerView, rate: Float)
    func playerVideo(playerFinished player: PlayerView)
}

public extension PlayerViewDelegate {
    
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: NSError?) {
        
    }
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: NSError?) {
        
    }
    func playerVideo(player: PlayerView, loadedTimeRanges: [PVTimeRange]) {
        
    }
    func playerVideo(player: PlayerView, duration: Double) {
        
    }
    func playerVideo(player: PlayerView, currentTime: Double) {
        
    }
    func playerVideo(player: PlayerView, rate: Float) {
        
    }
    func playerVideo(playerFinished player: PlayerView) {
        
    }
}

public enum PlayerViewFillMode {
    case ResizeAspect
    case ResizeAspectFill
    case Resize
    
    init?(videoGravity: String){
        switch videoGravity {
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
    
    var AVLayerVideoGravity:String {
        get {
            switch self {
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

private extension CMTime {
    static var zero:CMTime { return kCMTimeZero }
}
/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
@objc public class PlayerView: UIView {
    
    
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    private var timeObserverToken: AnyObject?
    private weak var lastPlayerTimeObserve: PVPlayer?
    
    private var urlsQueue: [NSURL]?
    //MARK: - Public Variables
    public weak var delegate: PlayerViewDelegate?
    
    public var loopVideosQueue = false
    public var player: PVPlayer? {
        get {
            return playerLayer.player as? PVPlayer
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    
    public var fillMode: PlayerViewFillMode! {
        didSet {
            playerLayer.videoGravity = fillMode.AVLayerVideoGravity
        }
    }
    
    
    public var currentTime: Double {
        get {
            guard let player = player else {
                return 0
            }
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            guard let timescale = player?.currentItem?.duration.timescale else {
                return
            }
            let newTime = CMTimeMakeWithSeconds(newValue, timescale)
            player!.seekToTime(newTime,toleranceBefore: CMTime.zero,toleranceAfter: CMTime.zero)
        }
    }
    public var interval = CMTimeMake(1, 60) {
        didSet {
            if rate != 0 {
                addCurrentTimeObserver()
            }
        }
    }
    
    public var rate: Float {
        get {
            guard let player = player else {
                return 0
            }
            return player.rate
        }
        set {
            if newValue == 0 {
                removeCurrentTimeObserver()
            } else if rate == 0 && newValue != 0 {
                addCurrentTimeObserver()
            }
            
            player?.rate = newValue
        }
    }
    // MARK: private Functions
    
    
    /**
     Add all observers for a PVPlayer
    */
    func addObserversPlayer(avPlayer: PVPlayer) {
        avPlayer.addObserver(self, forKeyPath: "status", options: [.New], context: &statusContext)
        avPlayer.addObserver(self, forKeyPath: "rate", options: [.New], context: &rateContext)
        avPlayer.addObserver(self, forKeyPath: "currentItem", options: [.Old,.New], context: &playerItemContext)
    }
    
    /**
        Remove all observers for a PVPlayer
     */
    func removeObserversPlayer(avPlayer: PVPlayer) {
        
        avPlayer.removeObserver(self, forKeyPath: "status", context: &statusContext)
        avPlayer.removeObserver(self, forKeyPath: "rate", context: &rateContext)
        avPlayer.removeObserver(self, forKeyPath: "currentItem", context: &playerItemContext)
        
        if let timeObserverToken = timeObserverToken {
            avPlayer.removeTimeObserver(timeObserverToken)
        }
    }
    func addObserversVideoItem(playerItem: PVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: [], context: &loadedContext)
        playerItem.addObserver(self, forKeyPath: "duration", options: [], context: &durationContext)
        playerItem.addObserver(self, forKeyPath: "status", options: [], context: &statusItemContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .playerItemDidPlayToEndTime, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
    }
    func removeObserversVideoItem(playerItem: PVPlayerItem) {
        
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: &loadedContext)
        playerItem.removeObserver(self, forKeyPath: "duration", context: &durationContext)
        playerItem.removeObserver(self, forKeyPath: "status", context: &statusItemContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
    }
    
    func removeCurrentTimeObserver() {
        
        if let timeObserverToken = self.timeObserverToken {
            lastPlayerTimeObserve?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }
    
    func addCurrentTimeObserver() {
        removeCurrentTimeObserver()
        
        lastPlayerTimeObserve = player
        self.timeObserverToken = player?.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) { [weak self] time-> Void in
            if let mySelf = self {
                self?.delegate?.playerVideo(mySelf, currentTime: mySelf.currentTime)
            }
        }
    }
    
    func playerItemDidPlayToEndTime(aNotification: NSNotification) {
        //notification of player to stop
        let item = aNotification.object as! PVPlayerItem
        if loopVideosQueue && player?.items().count == 1,
            let urlsQueue = urlsQueue {
            
            self.addVideosOnQueue(urls: urlsQueue, afterItem: item)
        }
        self.delegate?.playerVideo(playerFinished: self)
    }
    // MARK: public Functions
    
    public func play() {
        rate = 1
        //player?.play()
    }
    
    public func pause() {
        rate = 0
        //player?.pause()
    }
    
    
    public func stop() {
        currentTime = 0
        pause()
    }
    public func next() {
        player?.advanceToNextItem()
    }
    
    public func resetPlayer() {
        urlsQueue = nil
        guard let player = player else {
            return
        }
        player.pause()
        
        removeObserversPlayer(player)
        
        if let playerItem = player.currentItem {
            removeObserversVideoItem(playerItem)
        }
        self.player = nil
    }
    
    public func availableDuration() -> PVTimeRange {
        let range = self.player?.currentItem?.loadedTimeRanges.first
        if let range = range {
            return range.CMTimeRangeValue
        }
        return PVTimeRange.zero
    }
    
    public func screenshot() throws -> UIImage? {
        guard let time = player?.currentItem?.currentTime() else {
            return nil
        }
        
        return try screenshotCMTime(time)?.0
    }
    
    public func screenshotTime(time: Double? = nil) throws -> (UIImage, photoTime: CMTime)?{
        guard let timescale = player?.currentItem?.duration.timescale else {
            return nil
        }
        
        let timeToPicture: CMTime
        if let time = time {
            
            timeToPicture = CMTimeMakeWithSeconds(time, timescale)
        } else if let time = player?.currentItem?.currentTime() {
            timeToPicture = time
        } else {
            return nil
        }
        return try screenshotCMTime(timeToPicture)
    }
    
    private func screenshotCMTime(cmTime: CMTime) throws -> (UIImage,photoTime: CMTime)? {
        guard let player = player , let asset = player.currentItem?.asset else {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        var timePicture = CMTime.zero
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTime.zero
        imageGenerator.requestedTimeToleranceBefore = CMTime.zero
        
        let ref = try imageGenerator.copyCGImageAtTime(cmTime, actualTime: &timePicture)
        let viewImage: UIImage = UIImage(CGImage: ref)
        return (viewImage, timePicture)
    }
    public var url: NSURL? {
        didSet {
            guard let url = url else {
                urls = nil
                return
            }
            urls = [url]
        }
    }
    
    public var urls: [NSURL]? {
        willSet(newUrls) {
            
            resetPlayer()
            guard let urls = newUrls else {
                return
            }
            //reset before put another URL
            
            urlsQueue = urls
            let playerItems = urls.map { (url) -> PVPlayerItem in
                return PVPlayerItem(URL: url)
            }
            
            let avPlayer = PVPlayer(items: playerItems)
            self.player = avPlayer
            
            avPlayer.actionAtItemEnd = .Pause
            
            
            let playerItem = avPlayer.currentItem!
            
            addObserversPlayer(avPlayer)
            addObserversVideoItem(playerItem)
            
            // Do any additional setup after loading the view, typically from a nib.
        }
    }
    public func addVideosOnQueue(urls urls: [NSURL], afterItem: PVPlayerItem? = nil) {
        //on last item on player
        let item = afterItem ?? player?.items().last
        
        urlsQueue?.appendContentsOf(urls)
        //for each url found
        urls.forEach({ (url) in
            
            //create a video item
            let itemNew = PVPlayerItem(URL: url)
            
            //and insert the item on the player
            player?.insertItem(itemNew, afterItem: item)
        })
        
    }
    public func addVideosOnQueue(urls: NSURL..., afterItem: PVPlayerItem? = nil) {
        return addVideosOnQueue(urls: urls,afterItem: afterItem)
    }
    // MARK: public object lifecycle view
    
    override public class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    public convenience init() {
        self.init(frame: CGRect.zero)
        
        self.fillMode = .ResizeAspect
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.fillMode = .ResizeAspect
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.fillMode = .ResizeAspect
    }
    
    deinit {
        delegate = nil
        resetPlayer()
    }
    // MARK: private variables for context KVO
    
    private var statusContext = true
    private var statusItemContext = true
    private var loadedContext = true
    private var durationContext = true
    private var currentTimeContext = true
    private var rateContext = true
    private var playerItemContext = true
    
    
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        //print("CHANGE",keyPath)
        
        
        if context == &statusContext {
            
            guard let avPlayer = player else {
                super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
                return
            }
            self.delegate?.playerVideo(self, statusPlayer: avPlayer.status, error: avPlayer.error)
            
            
        } else if context == &loadedContext {
            
            let playerItem = player?.currentItem
            
            guard let times = playerItem?.loadedTimeRanges else {
                return
            }
            
            let values = times.map({ $0.CMTimeRangeValue})
            self.delegate?.playerVideo(self, loadedTimeRanges: values)
            
            
        } else if context == &durationContext{
            
            if let currentItem = player?.currentItem {
                self.delegate?.playerVideo(self, duration: currentItem.duration.seconds)
                
            }
            
        } else if context == &statusItemContext{
            //status of item has changed
            if let currentItem = player?.currentItem {
                
                self.delegate?.playerVideo(self, statusItemPlayer: currentItem.status, error: currentItem.error)
            }
            
        } else if context == &rateContext{
            guard let newRateNumber = (change?[NSKeyValueChangeNewKey] as? NSNumber) else{
                return
            }
            let newRate = newRateNumber.floatValue
            if newRate == 0 {
                removeCurrentTimeObserver()
            } else {
                addCurrentTimeObserver()
            }
            
            self.delegate?.playerVideo(self, rate: newRate)
            
        } else if context == &playerItemContext{
            guard let oldItem = (change?[NSKeyValueChangeOldKey] as? PVPlayerItem) else{
                return
            }
            removeObserversVideoItem(oldItem)
            guard let newItem = (change?[NSKeyValueChangeNewKey] as? PVPlayerItem) else{
                return
            }
            addObserversVideoItem(newItem)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
