//
//  ViewController.swift
//  KnowFlower
//
//  Created by Tey Ti Siang on 18/3/20.
//  Copyright © 2020 Tey Ti Siang. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let imagePicker = UIImagePickerController()
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

 
    
    @IBOutlet weak var imageViewOutlet: UIImageView!
    
    @IBOutlet weak var flowerDescriptionOutlet: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
    }
    
    func requestWiki(flowerName: String) {
        let parameters : [String:String] = [
         "format" : "json",
         "action" : "query",
         "prop" : "extracts|pageimages",
         "exintro" : "",
         "explaintext" : "",
         "titles" : flowerName,
         "indexpageids"  : "",
         "redirects" : "1",
         "pithumbsize" : "500"
         ]
        //Alamofire 5 and above
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let jsonResponse : JSON = JSON(value)
                print(jsonResponse)
                let pageId : String = jsonResponse["query"]["pageids"][0].stringValue
                //print(pageId)
                let extract : String = jsonResponse["query"]["pages"][pageId]["extract"].stringValue
                self.flowerDescriptionOutlet.text = extract
                
                let imageUrl = jsonResponse["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageViewOutlet.sd_setImage(with: URL(string: imageUrl), completed: nil)
            case .failure(let error): do {
                print("Error calling Wiki: \(error)")
                }
            }
        }
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage to CIImage")
            }
            detect(image: ciimage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading FlowerClassifier model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let result = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image.")
            }
            print(result)
            if let firstResult = result.first {
                self.navigationItem.title = "\(firstResult.identifier.capitalized) (\((firstResult.confidence*100).rounded(.down))%)" 
                self.requestWiki(flowerName: firstResult.identifier);
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
        
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

