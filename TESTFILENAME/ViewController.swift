//
//  ViewController.swift
//  TESTFILENAME
//
//  Created by sothea007 on 25/7/24.
//
import Foundation
import UIKit

class ViewController: UIViewController {
    // test PDF
    let testPDF = "https://platform.bizplay.co.kr/BBDownload?_weCloud_down_file={\"FILE_LIST\":[{\"FILE_IDNT_ID\":\"20240417_af2411a2-3d13-4f67-9059-01bb96c2ae9c\"}],\"IS_COMPACT\":\"S\",\"CMD\":\"preview\"}&_weCloud_callback=&_weCloud_apikey=RkEXY4BCJsZhEmYR1wvYZGDYBWHFP6Y5Ni_ZQ6F5qloBQ1p7oE&_weCloud_lnggDsnc=&_weCloud_file_opt=&_weCloud_render_js=&_weCloud_complate_data="
    
    // Test korean file = 대영텍 거래명세서 6월.pdf
    //    let testPDF = "https://platform-dev.bizplay.co.kr/BBDownload?_weCloud_down_file=%257B%2522FILE_LIST%2522%253A%255B%257B%2522FILE_IDNT_ID%2522%253A%252220240703_dc01b3ad-dde6-42c2-a763-16d1025b3caf%2522%257D%255D%252C%2522IS_COMPACT%2522%253A%2522S%2522%252C%2522CMD%2522%253A%2522preview%2522%257D&_weCloud_callback=&_weCloud_apikey=DqsZc0MQ6QFfXVj-dRaYyr8uU1iRGH-zYKoO_2G_yojuFIUcBi&_weCloud_lnggDsnc=&_weCloud_file_opt=&_weCloud_render_js=&_weCloud_complate_data="
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    
    @IBAction func click(_ sender: Any) {
        
        self.downloadFile(from: testPDF) { localURL, fileExtension,fileName in
            if let localURL = localURL, let fileExtension = fileExtension,let fileName = fileName {
                print("File downloaded to: \(localURL.path)")
                
                
                print("File name: \(fileName)")
                
                // Create new file name using the current date
                let newFileName = "\(fileName).\(fileExtension)"
                
                // Optionally, move the file to a desired location with the correct extension
                let destinationURL = localURL.deletingLastPathComponent().appendingPathComponent(newFileName)
                try? FileManager.default.moveItem(at: localURL, to: destinationURL)
                print("File moved to: \(destinationURL.path)")
                DispatchQueue.main.async {
                    let activityViewController = UIActivityViewController(activityItems: [destinationURL], applicationActivities: nil)
                    if let popoverPresentationController = activityViewController.popoverPresentationController {
                        popoverPresentationController.sourceView = self.view
                        popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popoverPresentationController.permittedArrowDirections = []
                    }
                    self.present(activityViewController, animated: true, completion: nil)
                }
                
            } else {
                print("Failed to download or determine file extension")
            }
        }
    }
    
    /// DownloadFile
    /// - Parameters:
    ///   - urlString: urlString description
    ///   - completion: completion localURL,fileExtension, fileName
    func downloadFile(from urlString: String, completion: @escaping (URL?, String?,String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, nil,nil)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(nil, nil, nil)
                return
            }
            
            // Get the MIME type from the response
            var fileExtension: String? = nil
            if let mimeType = response?.mimeType {
                fileExtension = self.mimeTypeToFileExtension(mimeType: mimeType)
            }
            
            // Get the file name from the response headers
            var fileName: String? = nil
            if let httpResponse = response as? HTTPURLResponse,
               let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
                fileName = self.extractFileName(from: contentDisposition)
            }
            
            if fileName == nil {
                fileName = url.lastPathComponent
            }
            
            completion(localURL, fileExtension, fileName)
        }
        
        task.resume()
    }
    
    /// ExtractFileName
    /// - Parameter contentDisposition: contentDisposition description
    /// - Returns: FileName
    func extractFileName(from contentDisposition: String) -> String? {
        // Pattern to extract the filename* or filename attribute
        let pattern = "filename\\*?=([^;]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = contentDisposition as NSString
        let results = regex?.matches(in: contentDisposition, options: [], range: NSRange(location: 0, length: nsString.length))
        
        if let result = results?.first {
            var fileName = nsString.substring(with: result.range(at: 1))
            
            // Handle encoding if the file name is encoded
            if fileName.hasPrefix("UTF-8''") {
                fileName = String(fileName.dropFirst(7)) // Remove the UTF-8'' prefix
            }
            
            // Decode percent-encoded file name
            fileName = fileName.removingPercentEncoding ?? fileName
            
            // Attempt to decode from ISO-8859-1 to UTF-8
            if let data = fileName.data(using: .isoLatin1), let decodedFileName = String(data: data, encoding: .utf8) {
                fileName = decodedFileName
            }
            
            // Remove surrounding quotes
            fileName = fileName.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            
            // Ensure there's no trailing quote
            if fileName.hasSuffix("\"") {
                fileName = String(fileName.dropLast())
            }
            
            return fileName
        }
        
        return nil
    }
    
    /// MimeTypeToFileExtension
    /// - Parameter mimeType: String
    /// - Returns: jpeg, jpg, png, pdf
    func mimeTypeToFileExtension(mimeType: String) -> String {
        switch mimeType {
        case "image/jpeg":
            return "jpg"
        case "image/png":
            return "png"
        case "application/pdf":
            return "pdf"
            // Add other MIME types and their extensions as needed
        default:
            return "bin"
        }
    }
}

