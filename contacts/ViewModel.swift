//
//  ViewModel.swift
//  contacts
//
//  Created by henning on 2017-07-25.
//  Copyright © 2017 Henning Hoffmann. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Alamofire
import PromiseKit

extension NSManagedObject
{
	public func string(_ key:String) -> String?
	{
		let string = self.value(forKeyPath: key) as? String
		return string
	}
	
	public func int(_ key:String) -> Int?
	{
		if let num = self.value(forKeyPath: key) as? NSNumber
		{
			return num.intValue
		}
		return nil
	}
}

open class ViewModel
{
	fileprivate var contacts: [NSManagedObject] = []	// contacts cache
	
	fileprivate var managedContext:NSManagedObjectContext?
	{
		get
		{
			guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else
			{
				return nil
			}
			
			return appDelegate.managedObjectContext
		}
	}
	
	var numContacts:Int
	{
		return contacts.count
	}
	
	init()
	{
		// load local contacts
		loadLocalContacts()
	}

	open func getContact(_ index:Int) -> (name:String?,mail:String?)
	{
		guard index < contacts.count else
		{
			return (nil,nil)
		}
		
		let contact = self.contacts[index]
		
		let name = contact.string( Constants.Keys.KEY_NAME )
		let mail = contact.string( Constants.Keys.KEY_MAIL )

		if (name == nil || name!.isEmpty) && (mail == nil || mail!.isEmpty)
		{
			return (nil, nil)
		}
		
		return (name, mail)
	}
	
	open func addContact(name: String, mail:String, cid:Int = -1)
	{
		guard let managedContext = self.managedContext else { return }
		
		let entity = NSEntityDescription.entity(forEntityName: "Contact", in: managedContext)
		let contact = NSManagedObject(entity: entity!, insertInto: managedContext)
		let contactID = (cid <= 0) ? self.generateID() : cid
		
		contact.setValue(name, forKeyPath: Constants.Keys.KEY_NAME)
		contact.setValue(mail, forKeyPath: Constants.Keys.KEY_MAIL)
		contact.setValue(NSNumber(value: contactID as Int), forKeyPath: Constants.Keys.KEY_ID)
		
		self.contacts.append(contact)
	}
	
	open func removeAllContacts()
	{
		guard let managedContext = self.managedContext else
		{
			return
		}
		
		do
		{
			for contact in contacts
			{
				managedContext.delete(contact)
			}
			
			try managedContext.save()
			contacts.removeAll()
		}
		catch let error as NSError
		{
			print("Could not delete all contacts. \(error), \(error.userInfo)")
		}
	}
	
	open func loadLocalContacts()
	{
		guard let managedContext = self.managedContext else
		{
			return
		}
  
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Contact")
		do
		{
			if let temp = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
			{
				contacts = temp
			}
		}
		catch let error as NSError
		{
			print("Could not fetch. \(error), \(error.userInfo)")
		}
	}
	
	open func deleteContact(at index:Int)
	{
		guard index < contacts.count, let managedContext = self.managedContext else
		{
			return
		}
		
		let contact = contacts[index]
		
		do
		{
			managedContext.delete(contact)
			try managedContext.save()
			contacts.remove(at: index)
		}
		catch let error as NSError
		{
			print("Could not delete. \(error), \(error.userInfo)")
		}
	}
}

extension ViewModel // internal / private stuff
{
	internal func generateID() -> Int
	{
		// let's just arbitrarily decide that any new ID should be greater than any existing ID's
		var greatestID:Int = 0
		
		for contact in contacts
		{
			if let contactID = contact.int( Constants.Keys.KEY_ID )
			{
				if contactID > greatestID
				{
					greatestID = contactID
				}
			}
		}
		
		greatestID += 1
		
		return greatestID
	}
	
	internal func contactExistsWith(_ thisID:Int) -> Bool
	{
		for contact in contacts
		{
			if let contactID = contact.int( Constants.Keys.KEY_ID ), contactID == thisID
			{
				return true
			}
		}
		
		return false
	}
	
	internal func addServerContacts(_ array:NSArray)
	{
		for obj in array
		{
			if let dict = obj as? NSDictionary, let contactID = dict[Constants.Keys.KEY_ID] as? NSNumber, !self.contactExistsWith(contactID.intValue)
			{
				if let name = dict[Constants.Keys.KEY_NAME] as? String, let mail = dict[Constants.Keys.KEY_MAIL] as? String
				{
					self.addContact(name: name, mail: mail, cid:contactID.intValue)
				}
			}
		}
		
		do
		{
			try self.managedContext?.save()
		}
		catch let error as NSError
		{
			print("Could not save. \(error), \(error.userInfo)")
		}
	}
	
	internal func dataPromise() -> Promise<Any> {
		
		return Promise { fulfill, reject in
			
			let urlString = "http://www.filltext.com/?rows=10&name=%7BfirstName%7D~%7BlastName%7D&mail=%7Bemail%7D&id=%7Bindex%7D&pretty=true"
			
			Alamofire.request(urlString, method: .get).responseJSON() { (response) in
				do
				{
					if let data = response.data
					{
						let jsonObject = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
						fulfill( jsonObject )
					}
					else
					{
						reject( NSError(domain: "MyDomain", code: 1, userInfo: nil) )
					}
				}
				catch let error
				{
					reject( error )
				}
			}
		}
	}
	
	internal func fetchServerContacts( completion: @escaping (Bool) -> Void )
	{
		firstly { Void -> Promise<Any> in
			return self.dataPromise()
		}.then 	{ jsonObject -> Void in
			if let array = jsonObject as? NSArray
			{
				self.addServerContacts(array)
				completion(true)
			}
		}.catch { (error) in
			completion(false)
		}
	}
}
