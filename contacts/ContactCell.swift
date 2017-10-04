//
//  ContactCell.swift
//  contacts
//
//  Created by henning on 2017-07-24.
//  Copyright © 2017 Henning Hoffmann. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift

class ContactCell: UITableViewCell
{
	static let identifier = "contactCellID"
	
	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var mail: UILabel!
	@IBOutlet weak var person: UIImageView!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?)
	{
		super.init(style: style, reuseIdentifier: reuseIdentifier)
	}
	
	required init?(coder aDecoder: NSCoder)
	{
		super.init( coder: aDecoder )
	}
	
	override func awakeFromNib()
	{
		super.awakeFromNib()
		
		self.person?.image = UIImage.fontAwesomeIcon(name: .userCircle, textColor: UIColor.black, size: CGSize(width: 45, height: 45))
		self.person?.alpha = 0.25
	}
}
