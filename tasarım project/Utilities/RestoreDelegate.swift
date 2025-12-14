//
//  RestoreDelegate.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import UIKit
import UniformTypeIdentifiers

class RestoreDelegate: NSObject, UIDocumentPickerDelegate {
    let viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first,
              let data = try? Data(contentsOf: url) else {
            return
        }
        
        if viewModel.restoreFromBackup(data) {
            // Show success alert
            let alert = UIAlertController(
                title: "Başarılı",
                message: "Yedek başarıyla geri yüklendi.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
}



