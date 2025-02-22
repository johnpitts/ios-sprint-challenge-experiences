//
//  VideoCaptureViewController.swift
//  ExperiencesPractice
//
//  Created by John Pitts on 7/12/19.
//  Copyright © 2019 johnpitts. All rights reserved.
//

import UIKit
import AVFoundation

class VideoCaptureViewController: UIViewController {
    
    lazy private var captureSession = AVCaptureSession()
    lazy private var fileOutput = AVCaptureMovieFileOutput()
    private var player: AVPlayer!
    
    @IBOutlet weak var cameraView: CameraPreviewView!
    @IBOutlet weak var recordButton: UIButton!
    
    var experienceMapViewController = ExperiencesMapViewController()
    
    var videoURL: URL?
//    {
//        didSet {
//            updateViews()
//        }
//    }
    
    var experience: Experience?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted == false {
                    fatalError("Please request user enable camera in Settings > Privacy")
                }
                
                DispatchQueue.main.async {
                    self.showCamera()
                }
            }
            
            
        case .restricted:
            // we don't have permission from the user because of parental controls
            fatalError("Please inform the user they cannot use app due to parental restrictions")
        case .denied:
            // we asked for permission, but the user said no
            fatalError("Please request user to enable camera usage in Settings > Privacy")
        case .authorized:
            // we asked for permission and they said yes.
            showCamera()
        @unknown default:
            fatalError()
        }

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        captureSession.stopRunning()
    }
    
    
    func showCamera() {
        
        let camera = bestCamera()
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera) else {
            fatalError("Can't create input from camera")
        }
        
        // Setup inputs
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            fatalError("Can't find microphone")
        }
        
        guard let microphoneInput = try? AVCaptureDeviceInput(device: microphone) else {
            fatalError("Can't create input from microphone")
        }
        
        if captureSession.canAddInput(microphoneInput) {
            captureSession.addInput(microphoneInput)
        }
        
        
        // Setup outputs
        if captureSession.canAddOutput(fileOutput) {
            captureSession.addOutput(fileOutput)
        }
        
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.canSetSessionPreset(.hd1920x1080)
        }
        
        captureSession.commitConfiguration()
        
        cameraView.session = captureSession

    }
    

    
    private func bestCamera() -> AVCaptureDevice {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }
        
        fatalError("No cameras exist - you're probably running on the simulator")
    }
    

    @IBAction func recordButtonTapped(_ sender: Any) {

        if fileOutput.isRecording {
            fileOutput.stopRecording()
            experience?.videoRecording = videoURL
            updateViews()
        } else {
            fileOutput.startRecording(to: newRecordingURL(), recordingDelegate: self)
        }
        
    }
    
    func newRecordingURL() -> URL {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let name = UUID().uuidString
        print("name: \(name)")
        let videoURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
        print("Url: \(videoURL)")
        
        return videoURL
    }
    
    
    func updateViews() {
        if fileOutput.isRecording {
            recordButton.setImage(UIImage(named: "Stop"), for: .normal)
            recordButton.tintColor = UIColor.blue
        } else {
            recordButton.setImage(UIImage(named: "Record"), for: .normal)
            recordButton.tintColor = UIColor.red                                  // my record images never show color, why?
        }
    }

    

    @IBAction func saveButtonTapped(_ sender: Any) {
    
        // use video file to create experience: done in fileOutput extension below
        
        guard let lat = experience?.location.latitude,
            let long = experience?.location.longitude,
            let image = experience?.image,
            let audioRecording = experience?.audioRecording,
            let nam = experience?.name else { return }
        
        experienceMapViewController.createExperience(name: nam, image: image, audioRecording: audioRecording, longitude: long, latitude: lat, videoRecording: videoURL!)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
}




extension VideoCaptureViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        
        DispatchQueue.main.async {
            self.updateViews()
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        videoURL = outputFileURL
        DispatchQueue.main.async {
            self.updateViews()
        }

    }
}
