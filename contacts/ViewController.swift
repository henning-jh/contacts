//
//  ViewController.swift
//  contacts
//
//  Created by henning on 2017-07-24.
//  Copyright © 2017 Henning Hoffmann. All rights reserved.
//

import UIKit
import CoreData
import MBProgressHUD
import FontAwesome_swift

class ViewController: UIViewController
{
	@IBOutlet weak var tableView: UITableView!
	
	fileprivate var viewModel = ViewModel()	// separate out the model access stuff into a separate class, for legibility and maintainability
	
	fileprivate var runningMail:String = ""	// the email the user is entering at the top of the screen
	fileprivate var runningName:String = ""	// the name the user is entering at the top of the screen
	
	lazy var refreshControl: UIRefreshControl = {	// you said I could create the UIRefreshControl via code
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(ViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
		return refreshControl
	}()
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
	
		self.title = "Simple Contacts"
		self.tableView.addSubview(self.refreshControl)
		
		// I have a bunch of table cell XIB's so that I can define the look using autolayout.
		
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
		self.tableView.register(UINib(nibName: "ContactCell", bundle: nil), forCellReuseIdentifier: "contactCellID")
		self.tableView.register(UINib(nibName: "CreateContactCell", bundle: nil), forCellReuseIdentifier: "createContactCellID")
		self.tableView.register(UINib(nibName: "HeaderCell", bundle: nil), forCellReuseIdentifier: "header")
		self.tableView.register(UINib(nibName: "AddContactCell", bundle: nil), forCellReuseIdentifier: "addContactCellID")
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(ViewController.onNameChanged(_:)),
		                                       name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_NAME_CHANGE),
		                                       object: nil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(ViewController.onMailChanged(_:)),
		                                       name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_MAIL_CHANGE),
		                                       object: nil)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		self.viewModel.loadLocalContacts()
	}
	
	open func onNameChanged( _ notification: Notification )
	{
		// let's keep track of the text the user is typing here
		
		if let userInfo = notification.userInfo as? [String:AnyObject],
		   let name = userInfo[Constants.Keys.KEY_NAME] as? String
		{
			self.runningName = name
		}
	}
	
	open func onMailChanged( _ notification: Notification )
	{
		// let's keep track of the text the user is typing here
		
		if let userInfo = notification.userInfo as? [String:AnyObject],
		   let mail = userInfo[Constants.Keys.KEY_MAIL] as? String
		{
			self.runningMail = mail
		}
	}
	
	func handleRefresh(refreshControl: UIRefreshControl)
	{
		// put up a progress indicator. often it goes by so fast you don't notice it
		
		let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
		hud.bezelView.color = UIColor.white
		hud.label.text = "Refreshing..."
		
		self.viewModel.fetchServerContacts() { (success) in
			
			MBProgressHUD.hide(for: self.view, animated: true)
			self.refreshControl.endRefreshing()
			
			if success
			{
				self.tableView.reloadData()
			}
			else
			{
				DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5)
				{
					self.alert( title:"Error", message:"Could not load content." )
				}
			}
		}
	}
	
	@IBAction func removeAllContacts(_ sender: Any)
	{
		let alert = UIAlertController(title: "Are you sure you want to delete all contacts?", message: "This is here for testing.", preferredStyle: UIAlertControllerStyle.alert)
		let deleteAction = UIAlertAction(title: "Delete All", style: UIAlertActionStyle.default)
		{
			[unowned self] action in

			let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
			hud.bezelView.color = UIColor.white
			hud.label.text = "Deleting..."
			
			DispatchQueue.global().async
			{
				self.viewModel.removeAllContacts()
				
				DispatchQueue.main.async
				{
					MBProgressHUD.hide(for: self.view, animated: true)
					
					self.tableView.reloadData()
				}
			}
		}
  
		let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil)
		
		alert.addAction(deleteAction)
		alert.addAction(cancelAction)
		
		self.present(alert, animated: true, completion: nil)
	}
	
	@IBAction func addContact(_ sender: AnyObject)
	{
		// This code was for testing creation of contacts before I got the proper UI in place.
		// I left it here in case you were curious.
		
		let alert = UIAlertController(title: "New Contact", message: "This is here for testing.", preferredStyle: UIAlertControllerStyle.alert)
		let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default)
			{
				[unowned self] action in
				
				guard let textField1 = alert.textFields?.first, let textField2 = alert.textFields?.last,
					let name = textField1.text,
					let mail = textField2.text
					else {
						return
				}
				
				DispatchQueue.main.async {
					self.createNewContact(name, mail)
					self.tableView.reloadData()
				}
			}
  
		let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: nil)

		alert.addTextField()
			{ textField in
				textField.placeholder = "Name"
			}
		alert.addTextField()
			{ textField in
				textField.placeholder = "Mail"
			}

		alert.addAction(saveAction)
		alert.addAction(cancelAction)

		self.present(alert, animated: true, completion: nil)
	}
	
	func createNewContact(_ name: String, _ mail:String)
	{
		_ = self.viewModel.addContact(name: name, mail: mail)
	}
}

extension ViewController: UITableViewDataSource
{
	func numberOfSections(in tableView: UITableView) -> Int
	{
		return 3
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
	{
		if indexPath.section == 0
		{
			return false
		}
		return true
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
	{
		if editingStyle == UITableViewCellEditingStyle.delete
		{
			self.viewModel.deleteContact(at:indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		if indexPath.section == 0
		{
			let cell = tableView.dequeueReusableCell(withIdentifier: "createContactCellID", for: indexPath) as? CreateContactCell
			// TODO cell?.delegate = self
			return cell!
		}
		else if indexPath.section == 1
		{
			// create this in its own section so that we can have some nice spacing between cells
			return tableView.dequeueReusableCell(withIdentifier: "addContactCellID", for: indexPath)
		}
		else
		{
			let contact = self.viewModel.getContact(indexPath.row)
			let cell = tableView.dequeueReusableCell(withIdentifier: "contactCellID", for: indexPath) as? ContactCell
			cell?.name?.text = contact.name
			cell?.mail?.text = contact.mail
			return cell!
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		if section == 0
		{
			return 1
		}
		else if section == 1
		{
			return 1
		}
		else
		{
			return self.viewModel.numContacts
		}
	}
	
}

extension ViewController: UITableViewDelegate
{
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		tableView.deselectRow(at: indexPath, animated: true)
	
		guard indexPath.section == 1, indexPath.row == 0 else
		{
			return
		}
		
		if self.runningMail.isEmpty
		{
			self.alert( title:"", message:"Please specify an email address." )
			return
		}
		if self.runningName.isEmpty
		{
			self.alert( title:"", message:"Please specify a name." )
			return
		}
		
		self.createNewContact(self.runningName, self.runningMail)
		self.tableView.reloadData()
		
		self.runningMail = ""
		self.runningName = ""
		
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.Keys.NOTIF_CONTACT_CREATED), object: nil )
		
		// scroll to bottom of view to show off the new contact
//		let numRows = tableView.numberOfRows(inSection: 2)
//		if numRows > 1
//		{
//			tableView.scrollToRow(at: IndexPath(row: (numRows-1), section: 2), at: UITableViewScrollPosition.bottom, animated: true)
//		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		if indexPath.section == 0
		{
			return 102
		}
		else if indexPath.section == 1
		{
			return 44
		}
		else
		{
			return 76
		}
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	{
		return 20
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: "header") as? HeaderCell
		
		if section == 0
		{
			cell?.label.text = "Add Contact"
		}
		else if section == 1
		{
			cell?.label.text = ""
		}
		else
		{
			cell?.label.text = "Contacts"
		}
		
		return cell?.contentView
	}
}