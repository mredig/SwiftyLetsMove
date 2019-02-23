//
//  OMGAlrt.swift
//
//  Created by Michael Redig on 12/9/18.
//  Copyright © 2018 Michael Redig. All rights reserved.
//

import Cocoa


class OMGAlrt {
	@discardableResult static func showAlert(withTitle title: String, andMessage message: String, andConfirmButtonText confirmText: String = "Okay", withCancelButtonText cancelText: String?, withAlertStyle style: NSAlert.Style = .informational, andClosure closure: @escaping (NSAlert) -> ()) -> NSApplication.ModalResponse {
		let alertVC = NSAlert()
		alertVC.messageText = title
		alertVC.informativeText = message
		alertVC.addButton(withTitle: confirmText)
		if let cancelText = cancelText {
			alertVC.addButton(withTitle: cancelText)
		}
		alertVC.alertStyle = style
		
		alertVC.showsSuppressionButton = true
		
		let response = alertVC.runModal()
		closure(alertVC)
		return response
	}
}
