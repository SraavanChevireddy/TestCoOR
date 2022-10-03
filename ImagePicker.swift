//
//  ImagePicker.swift
//  MESForGlobal
//
//  Created by Gowtham Reddy on 16/12/21.
//

import UIKit
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    
    @Binding var showAlert : Bool
    @Binding var alertMessage : String
    @Binding var imageData : Data?
    @Binding var showLoader: Bool
    @Binding var imageURL: URL?
    
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @Environment(\.presentationMode) private var presentationMode
    var imageState : ImagePickerState = .otherViews

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if picker.sourceType == .camera{
                guard let image = info[.originalImage] as? UIImage else{
                    print("You are null"); return
                }
                
                // Move the image to temp directory
                let objData = image.pngData()
                do{
                    let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("image.jpeg")
                    try objData?.write(to: tempPath, options: .atomic)
                    
                    self.parent.presentationMode.wrappedValue.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.4) {
                        self.parent.imageURL = tempPath
                        self.parent.imageData = objData!
                        
                        self.parent.showLoader  = true
                    }
                    return
                }catch{
                    self.parent.alertMessage = "Failed to update profile picture. Please try later"
                    self.parent.showAlert = true
                    print("Unable to Image URL")
                    return
                }
            }
            
            if parent.imageState == .profileView{
                guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {self.parent.alertMessage = "Failed to update profile picture. Please try later"
                    self.parent.showAlert = true
                    return
                }
                parent.presentationMode.wrappedValue.dismiss()
                guard let pickedImagedata = image.jpegData(compressionQuality: 1.0) else {
                    self.parent.alertMessage = "Failed to update profile picture. Please try later"
                    self.parent.showAlert = true
                    return
                }
                if let imageURL = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
                    let objData = imageURL.pngData()
                    do{
                        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("image.jpeg")
                        try objData?.write(to: tempPath, options: .atomic)
                        self.parent.imageURL = tempPath
                    }catch{
                        self.parent.alertMessage = "Failed to update profile picture. Please try later"
                        self.parent.showAlert = true
                        print("Unable to Image URL")
                        return
                    }
                }else{
                    self.parent.alertMessage = "Failed to update profile picture. Please try later"
                    self.parent.showAlert = true
                    print("Unable to Image URL")
                    return
                }
                    
                Util().storeUserDefaults(withObject: pickedImagedata, andKey: "profilePicture")
                parent.imageData = UserDefaults.standard.data(forKey: "profilePicture")!
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "profilePictureChanged"), object: self, userInfo: nil)
                }
            }else{
                guard let image = info[UIImagePickerController.InfoKey.imageURL] as? URL else {self.parent.alertMessage = "Failed to upload file. Please try later"
                    self.parent.showAlert = true
                    return
                }
                self.parent.presentationMode.wrappedValue.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                    self.parent.imageURL = image
                    do{
                        self.parent.imageData = try Data(contentsOf: image)
                    }catch{
                        print("Unable to create data!")
                    }
                    self.parent.showLoader  = true
                }
                return
                
//                if let imageURL = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
//                    let objData = imageURL.pngData()
//                    do{
//                        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("image.jpeg")
//                        try objData?.write(to: tempPath, options: .atomic)
//                        self.parent.imageURL = tempPath
//                        return
//                    }catch{
//                        self.parent.alertMessage = "Failed to update profile picture. Please try later"
//                        self.parent.showAlert = true
//                        print("Unable to Image URL")
//                        return
//                    }
//                }
//                else{
//                    print("Unable to Image URL")
//                    self.parent.alertMessage = "Failed to update profile picture. Please try later"
//                    self.parent.showAlert = true
//                    return
//                }
                
//                guard let pickedImagedata = image.jpegData(compressionQuality: 1.0) else {
//                    self.parent.alertMessage = "Failed to upload file. Please try later"
//                    self.parent.showAlert = true
//                    return
//                }
//                self.parent.imageData = pickedImagedata
                
                // Write your upload code here
                
            }
        }
        
        func getTimeStamp() -> String{
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "ddMMyyyyhhmmss"
            return formatter.string(from: date)
            }
    }
}


enum ImagePickerState{
    case profileView
    case otherViews
}
