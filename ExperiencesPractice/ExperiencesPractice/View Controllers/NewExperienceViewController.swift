//
//  NewExperienceViewController.swift
//  ExperiencesPractice
//
//  Created by John Pitts on 7/12/19.
//  Copyright © 2019 johnpitts. All rights reserved.
//

import UIKit
import Photos
//import CoreImage
import AVFoundation
protocol RecorderDelegate {
    func recorderDidChangeState(recorder: Recorder)
}

class NewExperienceViewController: UIViewController {

    @IBOutlet weak var experienceTitleTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPictureButton: UIButton!
    @IBOutlet weak var audioRecordButton: UIButton!
    
    let authorizationStatus = PHPhotoLibrary.authorizationStatus()
    let context = CIContext(options: nil)
    
    // these are the values which go into the model...
    var filteredImage: UIImage?
         //  record.fileURL
    
    lazy private var recorder = Recorder()
    
    var experience: Experience?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recorder.delegate = self
    }
    
    @IBAction func addImageButtonTapped(_ sender: Any) {
        
        // authorization from user to access image-Picker
        establishAuthorization()
        // showing filtered photo is done in establishedAuthorization, fix later for readability
        
        // add filteredImage to model
        
    }
    
    private func establishAuthorization() {
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { (status) in
                guard status == .authorized else {
                    NSLog("User said no")
                    self.presentInformationalAlertController(title: "Error", message: "To use a photo you must allow this application to access your photo library on this device")
                    return
                }
                self.presentImagePickerController()
            }
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "To use a photo experience you must authorize your photo library to be accessed by this app")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "you don't have permission to access photos")
        default: print("whoops, didn't think of this authorization problem, investigate")
        }
        presentImagePickerController()  // not sure this makes sense here in certain cases above
    }
    
    
    func presentImagePickerController() {
        
        let imagePicker = UIImagePickerController()
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "Photo Library unavailable")
            return
        }
        
        imagePicker.delegate = self
        
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func audioRecordButtonTapped(_ sender: Any) {
        
        // check if recorder already running, stop recorder if true, ow continue...
        //ensure access to recording functionality
        // get access to microphone instance
        // set up a recieving url to hold the file
        // record the audio and toggle button to "Stop Recording"
        
        recorder.toggleRecording()
        
        //TODO: store audio file in model
        
        
    }
    
    private func imageRender(byFiltering image: UIImage, with filter: CIFilter) -> UIImage {
        // let ciImage = originalImage?.ciImage Won't work from the Photo Library!
        
        guard let cgImage = image.flattened.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        
        filter.setValue(ciImage, forKey: "inputImage")  // key MUST match the API, so refer to developer.apple Core Image
        
        guard let outputCIImage = filter.outputImage else { return image }
        
        // render the image
        guard let outputCGImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return image }
        return UIImage(cgImage: outputCGImage)
        
    }
    
    private func updateViews() {

        audioRecordButton.setTitle(recorder.isRecording ? "Stop Recording" : "Record Audio", for: .normal)
    }
    

     // MARK: - Navigation
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "VideoSegue" {
            if let vidcapVC = segue.destination as? VideoCaptureViewController {
                
                guard let lat = Double(latitudeTextField.text!),
                    let long = Double(longitudeTextField.text!),
                    let image = filteredImage,
                    let audioRecording = recorder.fileURL,
                    let nam = experienceTitleTextField.text else { return }
                
                // videoRecording still nil here
                self.experience = Experience(name: nam, image: image, audioRecording: audioRecording, longitude: long, latitude: lat)
                

                
                experienceTitleTextField.text = ""
                longitudeTextField.text = ""
                latitudeTextField.text = ""
                
                vidcapVC.experience = experience
            }
        }
     }


}




extension NewExperienceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        guard let imageFilterPETonal = CIFilter(name: "CIPhotoEffectTonal") else { return }
        
        filteredImage = imageRender(byFiltering: image, with: imageFilterPETonal)
        
        imageView.image = filteredImage
        
        picker.dismiss(animated: true, completion: nil)
        
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension NewExperienceViewController: RecorderDelegate {
    
    func recorderDidChangeState(recorder: Recorder) {
        
        updateViews()
    }
}
