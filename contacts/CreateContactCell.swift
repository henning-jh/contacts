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

enum CreateContactField {
	case kName
	case kMail
}

protocol CreateContactCellDelegate: class {
	func textFieldChanged( type:CreateContactField, value: String )
}

class CreateContactCell: UITableViewCell
{
	@IBOutlet weak var emailIcon: UIImageView!
	@IBOutlet weak var nameIcon: UIImageView!
	@IBOutlet weak var name: UITextField!
	@IBOutlet weak var mail: UITextField!

	var delegate:CreateContactCellDelegate?
	
	open func onContactCreated()
	{
		name.text = ""
		mail.text = ""
	}

	override func awakeFromNib()
	{
		super.awakeFromNib()
		
		name.delegate = self
		mail.delegate = self
		
		self.emailIcon?.image = UIImage.fontAwesomeIcon(name: .envelope, textColor: UIColor.black, size: CGSize(width: 32, height: 32))
		self.emailIcon?.alpha = 0.4
		
		self.nameIcon?.image = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor.black, size: CGSize(width: 32, height: 32))
		self.nameIcon?.alpha = 0.4
		
		self.selectionStyle = UITableViewCellSelectionStyle.none
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
			delegate?.textFieldChanged( type: .kName, value:newString )
		}
		else if textField == mail
		{
			delegate?.textFieldChanged( type: .kMail, value:newString )
		}
		return true
	}
}
