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
    static let playerItemDidPlayToEndTime = #selector(PlayerView.playerItemDidPlayToEndTime(aNotification:))
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
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: Error?)
    func playerVideo(player: PlayerView, statusItemPlayer: PVItemStatus, error: Error?)
    func playerVideo(player: PlayerView, loadedTimeRanges: [PVTimeRange])
    func playerVideo(player: PlayerView, duration: Double)
    func playerVideo(player: PlayerView, currentTime: Double)
    func playerVideo(player: PlayerView, rate: Float)
    func playerVideo(playerFinished player: PlayerView)
}

public extension PlayerViewDelegate {
    
    func playerVideo(player: PlayerView, statusPlayer: PVStatus, error: Error?) {
        
    }
    func playerVideo(player: PlayerView, statusItemPlayer: PVStatus, error: Error?) {
        
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
    case resizeAspect
    case resizeAspectFill
    case resize
    
    init?(videoGravity: String){
        switch videoGravity {
        case AVLayerVideoGravityResizeAspect:
            self = .resizeAspect
        case AVLayerVideoGravityResizeAspectFill:
            self = .resizeAspectFill
        case AVLayerVideoGravityResize:
            self = .resize
        default:
            return nil
        }
    }
    
    var AVLayerVideoGravity:String {
        get {
            switch self {
            case .resizeAspect:
                return AVLayerVideoGravityResizeAspect
            case .resizeAspectFill:
                return AVLayerVideoGravityResizeAspectFill
            case .resize:
                return AVLayerVideoGravityResize
            }
        }
    }
}

private extension CMTime {
    static var zero:CMTime { return kCMTimeZero }
}
/// A simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
public class PlayerView: UIView {
    
    
    
    var playerLayer: AVPlayerLayer {
        get {
            return self.layer as! AVPlayerLayer
        }
    }
    
    override public class var layerClass: Swift.AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    
    private var timeObserverToken: AnyObject?
    private weak var lastPlayerTimeObserve: PVPlayer?
    
    private var urlsQueue: Array<URL>?
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
            player!.seek(to: newTime,toleranceBefore: CMTime.zero,toleranceAfter: CMTime.zero)
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
        avPlayer.addObserver(self, forKeyPath: "status", options: [.new], context: &statusContext)
        avPlayer.addObserver(self, forKeyPath: "rate", options: [.new], context: &rateContext)
        avPlayer.addObserver(self, forKeyPath: "currentItem", options: [.old,.new], context: &playerItemContext)
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
        NotificationCenter.default.addObserver(self, selector: .playerItemDidPlayToEndTime, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    func removeObserversVideoItem(playerItem: PVPlayerItem) {
        
        playerItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: &loadedContext)
        playerItem.removeObserver(self, forKeyPath: "duration", context: &durationContext)
        playerItem.removeObserver(self, forKeyPath: "status", context: &statusItemContext)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
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
        self.timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] time-> Void in
            if let mySelf = self {
                self?.delegate?.playerVideo(player: mySelf, currentTime: mySelf.currentTime)
            }
            } as AnyObject?
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
        
        removeObserversPlayer(avPlayer: player)
        
        if let playerItem = player.currentItem {
            removeObserversVideoItem(playerItem: playerItem)
        }
        self.player = nil
    }
    
    public func availableDuration() -> PVTimeRange {
        let range = self.player?.currentItem?.loadedTimeRanges.first
        if let range = range {
            return range.timeRangeValue
        }
        return PVTimeRange.zero
    }
    
    public func screenshot() throws -> UIImage? {
        guard let time = player?.currentItem?.currentTime() else {
            return nil
        }
        
        return try screenshotCMTime(cmTime: time)?.0
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
        return try screenshotCMTime(cmTime: timeToPicture)
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
        
        let ref = try imageGenerator.copyCGImage(at: cmTime, actualTime: &timePicture)
        let viewImage: UIImage = UIImage(cgImage: ref)
        return (viewImage, timePicture)
    }
    public var url: URL? {
        didSet {
            guard let url = url else {
                urls = nil
                return
            }
            urls = [url]
        }
    }
    
    public var urls: [URL]? {
        willSet(newUrls) {
            
            
            print("willSet urls")
            resetPlayer()
            guard let urls = newUrls else {
                return
            }
            //reset before put another URL
            
            urlsQueue = urls
            let playerItems = urls.map { (url) -> PVPlayerItem in
                return PVPlayerItem(url: url)
            }
            
            let avPlayer = PVPlayer(items: playerItems)
            self.player = avPlayer
            
            avPlayer.actionAtItemEnd = .pause
            
            
            let playerItem = avPlayer.currentItem!
            
            print("adding observers")
            addObserversPlayer(avPlayer: avPlayer)
            addObserversVideoItem(playerItem: playerItem)
            
            // Do any additional setup after loading the view, typically from a nib.
        }
    }
    public func addVideosOnQueue(urls: [URL], afterItem: PVPlayerItem? = nil) {
        //on last item on player
        let item = afterItem ?? player?.items().last
        
        urlsQueue?.append(contentsOf: urls)
        //for each url found
        urls.forEach({ (url) in
            
            //create a video item
            let itemNew = PVPlayerItem(url: url)
            
            
            //and insert the item on the player
            player?.insert(itemNew, after: item)
        })
        
    }
    
    
    
//    public func addVideosOnQueue(urls: [URL], afterItem: PVPlayerItem? = nil) {
//        return addVideosOnQueue(urls: urls,afterItem: afterItem)
//    }
    
    
    
    
    
    public convenience init() {
        self.init(frame: CGRect.zero)
        
        self.fillMode = .resizeAspect
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.fillMode = .resizeAspect
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.fillMode = .resizeAspect
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
    
    
    
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        
        //print("CHANGE",keyPath)
        
        
        if context == &statusContext {
            
            guard let avPlayer = player else {
                super.observeValue(forKeyPath: keyPath, of: object, change: change , context: context)
                return
            }
            //            self.delegate?.playerVideo(self, statusPlayer: avPlayer.status, error: avPlayer.error)
            self.delegate?.playerVideo(player: self, statusItemPlayer: avPlayer.status, error: avPlayer.error)
            //            self.delegate?.playerVideo(player: self, statusItemPlayer: avPlayer.status, error: avPlayer.error)
            
            
        } else if context == &loadedContext {
            
            let playerItem = player?.currentItem
            
            guard let times = playerItem?.loadedTimeRanges else {
                return
            }
            
            let values = times.map({ $0.timeRangeValue})
            self.delegate?.playerVideo(player: self, loadedTimeRanges: values)
            
            
        } else if context == &durationContext{
            
            if let currentItem = player?.currentItem {
                self.delegate?.playerVideo(player: self, duration: currentItem.duration.seconds)
                
            }
            
        } else if context == &statusItemContext{
            //status of item has changed
            if let currentItem = player?.currentItem {
                
                self.delegate?.playerVideo(player: self, statusItemPlayer: currentItem.status, error: currentItem.error)
            }
            
        } else if context == &rateContext{
            guard let newRateNumber = (change?[NSKeyValueChangeKey.newKey] as? NSNumber) else{
                return
            }
            let newRate = newRateNumber.floatValue
            if newRate == 0 {
                removeCurrentTimeObserver()
            } else {
                addCurrentTimeObserver()
            }
            
            //self.delegate?.playerVideo(self, rate: newRate)
            self.delegate?.playerVideo(player: self, rate: newRate)
            
        } else if context == &playerItemContext{
            guard let oldItem = (change?[NSKeyValueChangeKey.oldKey] as? PVPlayerItem) else{
                return
            }
            removeObserversVideoItem(playerItem: oldItem)
            guard let newItem = (change?[NSKeyValueChangeKey.newKey] as? PVPlayerItem) else{
                return
            }
            addObserversVideoItem(playerItem: newItem)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change , context: context)
        }
    }
}
