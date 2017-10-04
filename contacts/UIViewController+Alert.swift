//
//  UIViewController+Alert.swift
//  contacts
//
//  Created by Henning Hoffmann on 2017-10-01.
//  Copyright © 2017 Henning Hoffmann. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController
{
	public func alert(title:String, message:String)
	{
		let alert = UIAlertController( title:title, message:message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title:"OK", style: .cancel, handler:nil))
		self.present(alert, animated:true, completion: nil)
	}
}
