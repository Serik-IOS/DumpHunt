//
//  ReportDetailsVC.swift
//  DumpHunt
//
//  Created by Serik on 22.11.2019.
//  Copyright © 2019 Serik_Klement. All rights reserved.
//

import UIKit

protocol ReportListVCDelegate: class {
    func setIsGetReports(_ isGetReports: Bool)
}

final class ReportDetailsVC: BaseVC {

    // MARK: - Outlets

    @IBOutlet var dumpImageView: UIImageView!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!

    // MARK: - Properties

    var report: Report?
    weak var delegate: ReportListVCDelegate?
    weak var submitAction : UIAlertAction?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setReport()
    }
    
    // Mark: Action
    
    override func leftButtonAction(_ button: UIBarButtonItem) {
        super.leftButtonAction(button)
        
        delegate?.setIsGetReports(false)
    }
        
    @IBAction func mapActionButton(_ sender: UIButton) {
        showGoogleMapsVC()
    }
    
    @IBAction func menuAction(_ sender: UIButton) {
        
        Utill.showReportActionSheet(vc: self,
                                    success: { [weak self] () in
                                        guard let self = self else { return }
                                        self.reportContent()
        })
    }
    
    // Mark: Methods

    private func setReport() {
        
        if let textUrl = report?.photoURL,
            let url = URL(string: textUrl) {
            dumpImageView.kf.setImage(with: url,
                                      placeholder: Utill.getPlaceholder(),
                                      options: [.transition(.fade(1)),
                                                .cacheOriginalImage])
        } else {
            dumpImageView.image = Utill.getPlaceholder()
        }
        
        if let latitude = report?.latitude {
            latitudeLabel.text = String(latitude)
        }
        
        if let longitude = report?.longitude {
            longitudeLabel.text = String(longitude)
        }

        if let date = report?.date {
            dateLabel.text = Utill.getFormattedDate(string: date)
        }

    }
    
    private func reportContent() {

        let alert = UIAlertController(title: nil,
                                      message: Constants.reasonСomplaint,
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.addTarget(self,
                                action: #selector(self.reportReasonChanged(sender:)),
                                for: .editingChanged)
        }
        
        let action = UIAlertAction(title: Constants.send,
                                   style: .default,
                                   handler: { [weak alert] (_) in
                                    guard let textField = alert?.textFields![0],
                                        let complain = textField.text,
                                        !complain.isEmpty else { return }
                                    self.showSpinner()
                                    self.postComplainReport(complain)
        })
        
        alert.addAction(action)
        alert.addAction(UIAlertAction(title: Constants.cancel, style: .cancel))
        
        self.submitAction = action
        action.isEnabled = false
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func reportReasonChanged(sender:UITextField){
        self.submitAction?.isEnabled = sender.text?.isEmpty == false
    }

}

// MARK: - NetworkClient

extension ReportDetailsVC {
    
    private func postComplainReport(_ complain: String) {
        
        self.networkClient.postComplainReport(reportID: self.report?.id,
                                              complain: complain,
                                              success: { [weak self] () in
                                                guard let self = self else { return }
                                                DispatchQueue.main.async {
                                                    self.hideSpinner()
                                                    self.showSuccessAlert(Constants.compleintSent)
                                                }
            },
                                              failure:
            { [weak self] (message) in
                guard let self = self else { return }
                self.hideSpinner()
                self.showErrorAlert(message)
        })
    }
    
    private func showSuccessAlert(_ message: String?) {
        
        let alert = UIAlertController(title: nil,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.ok,
                                      style: .default,
                                      handler: nil))
        self.present(alert, animated: true)
    }
    
}

// MARK: - Transition

extension ReportDetailsVC {
    
    private func showGoogleMapsVC() {
        
        guard let vc = GoogleMapsVC.instanceFromStoryboard(.googleMapsVC) as? GoogleMapsVC else { return }
        vc.typeVC = .open
        vc.latitude = report?.latitude
        vc.longitude = report?.longitude
        pushViewController(vc)
    }
    
}
