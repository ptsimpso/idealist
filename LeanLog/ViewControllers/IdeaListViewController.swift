//
//  IdeaListViewController.swift
//  LeanLog
//
//  Created by Peter Simpson on 2/26/15.
//  Copyright (c) 2015 Pete Simpson. All rights reserved.
//

import UIKit
import CoreData

class IdeaListViewController: UITableViewController, ModalDelegate {

    let kHeaderHeight: CGFloat = 50.0
    let kPaidKey = "unlimited"
    let kIAPIdentifer = "me.petersimpson.idealist.unlimited"
    let kDonation0 = "me.petersimpson.idealist.donation0"
    let kDonation1 = "me.petersimpson.idealist.donation1"
    let kDonation2 = "me.petersimpson.idealist.donation2"
    let kDonation3 = "me.petersimpson.idealist.donation3"
    let kDetailSegue = "DetailSegue"
    let kSettingsSegue = "SettingsSegue"
    let kAddIdeaSegue = "AddIdeaSegue"
    
    let coreDataStack = CoreDataStack.sharedInstance
    
    // Data source when "All" is selected
    var ideas: [Idea] = [];
    
    // Data sources when "Categories" is selected
    var ungrouped: [Idea] = [];
    var groups: [Group] = [];
    var groupIdeaArrays: [[Idea]] = [];
    
    var toggleArray: [Int] = [] // Keeps track of which section headers are tapped
    
    var accentColor = UIColor(red: 68/255.0, green: 188/255.0, blue: 201/255.0, alpha: 1.0)
    let defaultColor = UIColor(red: 68/255.0, green: 188/255.0, blue: 201/255.0, alpha: 1.0)
    
    @IBOutlet weak var searchSegmentedControl: UISegmentedControl!
    
    let formatter: NSDateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        // Set up gold-strip background view
        let backgroundView = UIView(frame: CGRectMake(self.tableView.frame.width-6, 0, 6.0, self.tableView.frame.height));
        let goldView = UIView(frame: CGRectMake(self.tableView.frame.width-6, 0, 6.0, self.tableView.frame.height))
        goldView.backgroundColor = UIColor(red: 1.0, green: 213/255.0, blue: 0, alpha: 1.0)
        backgroundView.addSubview(goldView);
        self.tableView.backgroundView = backgroundView

        formatter.dateFormat = "h:mm a, MMM d"
        formatter.AMSymbol = "am"
        formatter.PMSymbol = "pm"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // iCloud sync notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreDidChange", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "persistentStoreWillChange:", name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: coreDataStack.managedObjectContext!.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receiveICloudChanges:", name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coreDataStack.managedObjectContext!.persistentStoreCoordinator)

        refreshData()
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("firstRun") {
            let introView = IntroView(frame: self.navigationController!.view.bounds)
            self.navigationController!.view.addSubview(introView)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: coreDataStack.managedObjectContext!.persistentStoreCoordinator)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coreDataStack.managedObjectContext!.persistentStoreCoordinator)
        
        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            return 1
        } else {
            return groups.count + 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            if ideas.count > 0 {
                return ideas.count
            }
            return 1
        } else {
            if contains(toggleArray, section) {
                if section == groupIdeaArrays.count {
                    return ungrouped.count
                } else {
                    let ideaArray = groupIdeaArrays[section]
                    return ideaArray.count
                }
            } else {
                return 0
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            return super.tableView(tableView, heightForHeaderInSection: section)
        } else {
            return kHeaderHeight
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            return super.tableView(tableView, viewForHeaderInSection: section)
        } else {
            var sectionTitle: String
            if section == groups.count {
                sectionTitle = "Uncategorized"
            } else {
                let group = groups[section]
                sectionTitle = group.title
            }
            let headerView = IdeaHelper.createSectionHeader(section, title: sectionTitle, headersCount: groups.count + 1, parentVC: self)
            
            return headerView
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if ideas.count > 0 || searchSegmentedControl.selectedSegmentIndex == 1 {
            return 60.0
        }
        return 142.0
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            if ideas.count > 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("IdeaCell", forIndexPath: indexPath) as! IdeaTitleCell
                
                IdeaHelper.setUpIdeaCell(cell, idea: ideas[indexPath.row], row: indexPath.row, count: ideas.count, formatter: formatter)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("NoDataCell", forIndexPath: indexPath) as! UITableViewCell
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("IdeaCell", forIndexPath: indexPath) as! IdeaTitleCell
            
            var rowIdea: Idea!
            var count: Int!
            
            if indexPath.section == groupIdeaArrays.count {
                rowIdea = ungrouped[indexPath.row]
                count = ungrouped.count
            } else {
                let ideaArray = groupIdeaArrays[indexPath.section]
                rowIdea = ideaArray[indexPath.row]
                count = ideaArray.count
            }
            
            IdeaHelper.setUpIdeaCell(cell, idea: rowIdea, row: indexPath.row, count: count, formatter: formatter)
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete") { (rowAction, indexPath) -> Void in
            if self.searchSegmentedControl.selectedSegmentIndex == 0 {
                let idea = self.ideas.removeAtIndex(indexPath.row)
                self.coreDataStack.deleteIdea(idea)
                
                if self.ideas.count == 0 {
                    tableView.reloadData()
                } else {
                    // Delete the row from the data source
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                }
            } else {
                if indexPath.section == self.groupIdeaArrays.count {
                    let idea = self.ungrouped.removeAtIndex(indexPath.row)
                    self.coreDataStack.deleteIdea(idea)
                    
                    if self.ungrouped.count == 0 {
                        tableView.reloadData()
                    } else {
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                } else {
                    let idea = self.groupIdeaArrays[indexPath.section].removeAtIndex(indexPath.row)
                    self.coreDataStack.deleteIdea(idea)
                    
                    if self.groupIdeaArrays[indexPath.section].count == 0 {
                        tableView.reloadData()
                    } else {
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    }
                }
            }
        }
        deleteAction.backgroundColor = UIColor(red: 237/255.0, green: 55/255.0, blue: 0, alpha: 1.0)
        return [deleteAction]
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }

    // MARK: Actions
    
    func sectionTogglePressed(sender: SectionToggleButton) {
        if contains(toggleArray, sender.tag) {
            toggleArray.removeAtIndex(find(toggleArray, sender.tag)!)
        } else {
            toggleArray.append(sender.tag)
        }
        
        self.tableView.reloadSections(NSIndexSet(index: sender.tag), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    @IBAction func searchControlPressed(sender: UISegmentedControl) {
        refreshData()
    }

    @IBAction func addPressed(sender: UIBarButtonItem) {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let searchIndex = searchSegmentedControl.selectedSegmentIndex
        
        var totalIdeas: Int = 0
        if searchIndex == 1 {
            totalIdeas += ungrouped.count
            for ideaArray in groupIdeaArrays {
                totalIdeas += ideaArray.count
            }
        }
        if userDefaults.boolForKey(kPaidKey) || (searchIndex == 0 && ideas.count < 3) || (searchIndex == 1 && totalIdeas < 3) {
            Branch.getInstance().userCompletedAction("created_idea")
            
            performSegueWithIdentifier(kAddIdeaSegue, sender: nil)
            
        } else {
            Branch.getInstance().userCompletedAction("reached_limit")
            
            PFConfig.getConfigInBackgroundWithBlock {
                (var config, error) -> Void in
                if error == nil {
                    
                } else {
                    config = PFConfig.currentConfig()
                }
                
                var paidApp: Bool
                var paidAppOpt = config?.objectForKey("paidApp") as? Bool
                if let paidAppBool = paidAppOpt {
                    paidApp = paidAppBool
                } else {
                    paidApp = false
                }
                
                if paidApp {
                    Heap.setEventProperties(["Payment":"Paid"])
                    userDefaults.setBool(true, forKey: self.kPaidKey)
                    userDefaults.synchronize()
                    self.coreDataStack.insertNewPurchase("paid")
                    self.performSegueWithIdentifier(self.kAddIdeaSegue, sender: nil)
                } else {
                    
                    var donation: Bool
                    let donationOpt = config?.objectForKey("donation") as? Bool
                    if let donationOpt = donationOpt {
                        donation = donationOpt
                    } else {
                        donation = false
                    }
                    
                    if donation {
                        var purchaseAlert = UIAlertController(title: "Limit Reached", message: "Unlock the ability to create unlimited ideas for free or by donating to the developer.", preferredStyle: UIAlertControllerStyle.Alert)
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Free", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.buyProduct(self.kDonation0, block: { (error:NSError?) -> Void in
                                if error != nil {
                                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            })
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "$0.99", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.buyProduct(self.kDonation1, block: { (error:NSError?) -> Void in
                                if error != nil {
                                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            })
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "$1.99", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.buyProduct(self.kDonation2, block: { (error:NSError?) -> Void in
                                if error != nil {
                                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            })
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "$3.99", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.buyProduct(self.kDonation3, block: { (error:NSError?) -> Void in
                                if error != nil {
                                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            })
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Restore", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.restore()
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
                        
                        self.presentViewController(purchaseAlert, animated: true, completion: nil)
                    } else {
                        var productPriceString: String
                        var productPriceConfig = config?.objectForKey("productPrice") as? String
                        if let productPrice = productPriceConfig {
                            productPriceString = productPrice
                        } else {
                            productPriceString = "$1.99"
                        }
                        
                        var purchaseAlert = UIAlertController(title: "Limit Reached", message: "Unlock the ability to create unlimited ideas for \(productPriceString)", preferredStyle: UIAlertControllerStyle.Alert)
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Purchase", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.buyProduct(self.kIAPIdentifer, block: { (error:NSError?) -> Void in
                                if error != nil {
                                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                }
                            })
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Restore", style: .Default, handler: { (action: UIAlertAction!) in
                            PFPurchase.restore()
                        }))
                        
                        purchaseAlert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler:nil))
                        
                        self.presentViewController(purchaseAlert, animated: true, completion: nil)
                    }
                }
                
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: IdeaTitleCell = self.tableView.cellForRowAtIndexPath(indexPath) as! IdeaTitleCell
        accentColor = cell.ideaTitleLabel.textColor
        performSegueWithIdentifier(kDetailSegue, sender: indexPath)
    }
    
    // MARK: Refresh data
    
    func refreshData() {
        if searchSegmentedControl.selectedSegmentIndex == 0 {
            if let fetchResults = coreDataStack.fetchIdeasWithPredicate(nil) {
                ideas = fetchResults
            }
        } else {
            if let groupResults = coreDataStack.fetchGroups() {
                groupIdeaArrays.removeAll(keepCapacity: true)
                groups = groupResults
                for singleGroup: Group in groups {
                    var groupIdeas: [Idea] = singleGroup.ideas.allObjects as! [Idea]
                    groupIdeas.sort({ (first: Idea, second: Idea) -> Bool in
                        let firstInt = first.priority.integerValue
                        let secondInt = second.priority.integerValue
                        if firstInt == secondInt {
                            if first.updatedAt.compare(second.updatedAt) == NSComparisonResult.OrderedDescending {
                                return true
                            }
                            return false
                        } else {
                            return firstInt > secondInt
                        }
                    })
                    groupIdeaArrays.append(groupIdeas)
                }
            }
            let predicate = NSPredicate(format: "groups.@count == 0")
            if let ungroupedIdeas = coreDataStack.fetchIdeasWithPredicate(predicate) {
                ungrouped = ungroupedIdeas
            }
        }
        
        self.tableView.reloadData()
    }
    
    // iCloud / Core Data sync notifications
    func persistentStoreDidChange() {
        println("did change")
    }
    
    func persistentStoreWillChange(notification: NSNotification) {
        println("will change")
        coreDataStack.managedObjectContext!.performBlock { () -> Void in
            var error: NSError? = nil
            self.coreDataStack.managedObjectContext!.save(&error)
            if error != nil {
                println("Save error: \(error)")
            } else {
                self.coreDataStack.managedObjectContext!.reset()
                self.refreshData()
            }
        }
    }
    
    func receiveICloudChanges(notification: NSNotification) {
        println("icloud")
        coreDataStack.managedObjectContext!.performBlock { () -> Void in
            self.coreDataStack.managedObjectContext!.mergeChangesFromContextDidSaveNotification(notification)
            self.refreshData()
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kDetailSegue {
            
            let indexPath = sender as! NSIndexPath
            
            let destination = segue.destinationViewController as! DetailsViewController
            destination.accentColor = accentColor
            destination.defaultColor = defaultColor
            
            if searchSegmentedControl.selectedSegmentIndex == 0 {
                destination.idea = ideas[indexPath.row]
            } else {
                if indexPath.section == groupIdeaArrays.count {
                    destination.idea = ungrouped[indexPath.row]
                } else {
                    let ideaArray = groupIdeaArrays[indexPath.section]
                    destination.idea = ideaArray[indexPath.row]
                }
            }
            
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        } else if segue.identifier == kSettingsSegue {
            let destination = segue.destinationViewController as! SettingsViewController
            destination.delegate = self
        } else if segue.identifier == kAddIdeaSegue {
            let destination = segue.destinationViewController as! AddIdeaViewController
            destination.delegate = self
        }
    }
    
    func minimizeView(sender: AnyObject) {
        spring(0.7, {
            self.navigationController!.view.transform = CGAffineTransformMakeScale(0.935, 0.935)
        })
    }
    
    func maximizeView(sender: AnyObject) {
        spring(0.7, {
            self.navigationController!.view.transform = CGAffineTransformMakeScale(1.0, 1.0)
        })
    }
    
    func dismissModalHandler(sender: AnyObject?) {
        let ideaTitleOpt = sender as! String?
        if let ideaTitle = ideaTitleOpt {
            let newIdea = coreDataStack.insertNewIdea()
            newIdea.title = ideaTitle
            var indexPath: NSIndexPath!
            
            if searchSegmentedControl.selectedSegmentIndex == 0 {
                indexPath = NSIndexPath(forRow: 0, inSection: 0)
                ideas.insert(newIdea, atIndex: 0)
            } else {
                indexPath = NSIndexPath(forRow: 0, inSection: groupIdeaArrays.count)
                ungrouped.insert(newIdea, atIndex: 0)
            }
            
            accentColor = defaultColor
            performSegueWithIdentifier(kDetailSegue, sender: indexPath)
        }
    }

}
