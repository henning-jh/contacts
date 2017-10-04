//
//  CreateContactCell.swift
//  contacts
//
//  Created by Henning Hoffmann on 2017-07-26.
//  Copyright © 2017 Henning Hoffmann. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CreateContactCell: UITableViewCell
{
	@IBOutlet weak var emailIcon: UIImageView!
	@IBOutlet weak var nameIcon: UIImageView!
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var mail: UITextField!
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		if name.delegate == nil
		{
			name.delegate = self
			mail.delegate = self
			
			NotificationCenter.default.addObserver(self,
			                                       selector: #selector(CreateContactCell.onContactCreated(_:)),
			                                       name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_CONTACT_CREATED),
			                                       object: nil)
			
		}
	}
	
	open func onContactCreated( _ notification: Notification )
	{
		name.text = ""
		mail.text = ""
	}

	override func awakeFromNib()
	{
		super.awakeFromNib()
		
		self.emailIcon?.image = UIImage.fontAwesomeIcon(name: .envelope, textColor: UIColor.black, size: CGSize(width: 32, height: 32))
		self.emailIcon?.alpha = 0.4
		
		self.nameIcon?.image = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor.black, size: CGSize(width: 32, height: 32))
		self.nameIcon?.alpha = 0.4
	}
}

extension CreateContactCell: UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		textField.resignFirstResponder()
		return false
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	{
		let newString = textField.text != nil ? (textField.text! as NSString).replacingCharacters(in: range, with: string) : ""

		if textField == name
		{
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_NAME_CHANGE),
			                                object: self,
			                                userInfo: [Constants.Keys.KEY_NAME:newString])
		}
		if textField == mail
		{
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_MAIL_CHANGE),
			                                object: self,
			                                userInfo: [Constants.Keys.KEY_MAIL:newString])
		}
		return true
	}
}
