//
//  ViewController.swift
//  PlayerVideo
//
//  Created by David Alejandro on 2/17/16.
//  Copyright © 2016 David Alejandro. All rights reserved.
//

import UIKit
import PlayerView
import AVFoundation




class ViewController: UIViewController {
    
    @IBOutlet var slider: UISlider!
    
    @IBOutlet var progressBar: UIProgressView!
    
    @IBOutlet var playerVideo: PlayerView!
    
    @IBOutlet var rateLabel: UILabel!
    
    @IBOutlet var playButton: UIButton!
    
    
    var duration: Float!
    var isEditingSlider = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("will load")
        //let controller = PlayerVideoViewController()
        //controller.delegate = self
        //controller.view.frame = self.view.bounds
        //addChildViewController(controller)
        //view.insertSubview(controller.view, atIndex: 0)
        
        
        //let playerVideo = PlayerView()
        //playerVideo.delegate = self
        //playerVideo.frame = self.view.bounds
        //view.insertSubview(playerVideo, atIndex: 0)
        
        
        playerVideo.delegate = self
        let url = NSURL(string: "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_30mb.mp4")!
        
        playerVideo.setUrl(url)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func sliderChange(sender: UISlider) {
        //print(sender.value)
        
        playerVideo.currentTime = Double(sender.value)
    }
    
    @IBAction func sliderBegin(sender: AnyObject) {
        print("beginEdit")
        isEditingSlider = true
    }
    
    @IBAction func sliderEnd(sender: AnyObject) {
        print("endEdit")
        isEditingSlider = false
    }
    
    
    
    @IBAction func backwardTouch(sender: AnyObject) {
        playerVideo.rate = playerVideo.rate - 0.5
    }
    
    @IBAction func playTouch(sender: AnyObject) {
        if playerVideo.rate == 0 {
            playerVideo.play()
        } else {
            playerVideo.pause()
        }
    }
    
    @IBAction func fowardTouch(sender: AnyObject) {
        playerVideo.rate = playerVideo.rate + 0.5
    }
    
    override func loadView() {
        super.loadView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


extension ViewController: PlayerViewDelegate {
    
    func playerVideo(player: PlayerView, statusPlayer: PlayerViewStatus, error: NSError?) {
        print(statusPlayer)
    }
    
    func playerVideo(player: PlayerView, statusItemPlayer: PlayerViewItemStatus, error: NSError?) {
        
    }
    func playerVideo(player: PlayerView, loadedTimeRanges: [PlayerviewTimeRange]) {
        
        let dur2 = Float(loadedTimeRanges.first!.end.seconds)
        let progress = dur2 / duration
        progressBar?.progress = progress
        
        if loadedTimeRanges.count > 1 {
            print(loadedTimeRanges.count)
        }
        //print(progress,duration, dur2)
    }
    func playerVideo(player: PlayerView, duration: Double) {
        //print(duration.seconds)
        self.duration = Float(duration)
        slider?.maximumValue = Float(duration)
    }
    
    func playerVideo(player: PlayerView, currentTime: Double) {
        if !isEditingSlider {
            slider.value = Float(currentTime)
        }
        //print(currentTime.seconds)
    }
    
    func playerVideo(player: PlayerView, rate: Float) {
        rateLabel.text = "x\(rate)"
        
        
        let buttonImageName = rate == 0.0 ? "PlayButton" : "PauseButton"
        
        let buttonImage = UIImage(named: buttonImageName)
        
        playButton.setImage(buttonImage, forState: .Normal)
        
        //slider.value = Float(currentTime)
        //print(currentTime.seconds)
    }
}