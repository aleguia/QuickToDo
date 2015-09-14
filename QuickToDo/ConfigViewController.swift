//
//  ConfigViewController.swift
//  QuickToDo
//
//  Created by Bratislav Ljubisic on 3/15/15.
//  Copyright (c) 2015 Bratislav Ljubisic. All rights reserved.
//

import UIKit
import CloudKit

class ConfigViewController: UIViewController {

    @IBOutlet weak var iCloudEmail: UITextField!
    @IBOutlet weak var iCloudId: UILabel!
    @IBOutlet weak var iCloudName: UILabel!
    @IBOutlet weak var iCloudLastname: UILabel!
    @IBOutlet weak var sendInvitationButton: UIButton!
    @IBOutlet weak var shareSwitch: UISwitch!
    @IBOutlet weak var findView: UIView!
    @IBOutlet weak var showInviteList: UIView!
    @IBOutlet weak var cancelSubscription: UIButton!
    @IBOutlet weak var nameSubscription: UILabel!
    @IBOutlet weak var receiverSubscription: UILabel!
    
    
    var iCloudIdVar: String = String()
    var myICloudVar: String = String()
    var iCloudNameVar: String = String()
    
    var shareSwitchVar: Bool = false
    let dataManager: QuickToDoDataManager = QuickToDoDataManager.sharedInstance
    let configManager: ConfigManager = ConfigManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configManager.readConfigPlist()
        
        if (configManager.sharingEnabled == 1) {
            shareSwitchVar = true
            self.findView.hidden = false
            dataManager.cdGetInvitation(showInviteList)
        }
        else {
            shareSwitchVar = false
            self.findView.hidden = true
        }
        
        shareSwitch.setOn(shareSwitchVar, animated: true)
        
        // find self recordId
        
        
        let container: CKContainer = CKContainer.defaultContainer()
        
        
        
        container.fetchUserRecordIDWithCompletionHandler({ (recordId: CKRecordID?, error: NSError?) -> Void in
            if let unwrappedRecordId = recordId {
                self.myICloudVar = unwrappedRecordId.recordName
                self.configManager.selfRecordId = unwrappedRecordId.recordName
            } else {
                print("The optional is nil!")
            }
            
            
        })
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeShareSwitch(sender: AnyObject) {
        
        if(shareSwitchVar) {
            self.findView.alpha = 1.0
            findView.hidden = true
            self.showInviteList.hidden = true
            UIView.animateWithDuration(0.25, animations: {
                self.findView.alpha = 0.0
                }, completion: {
                    (value: Bool) in
                    print(">>> Animation done.")
            })
            shareSwitchVar = false
        }
        else {
            
            
            
            self.findView.alpha = 0.0
            findView.hidden = false
            UIView.animateWithDuration(0.25, animations: {
                self.findView.alpha = 1.0
                }, completion: {
                    (value: Bool) in
                    print(">>> Animation done.")
            })
            shareSwitchVar = true
        }
        
        
    }
    
    
    @IBAction func sendInvitation(sender: AnyObject) {
        
        
        
        if(self.iCloudIdVar != "") {
            let invitation = InvitationObject()
            
            invitation.sender = self.myICloudVar
            invitation.receiver = self.iCloudId.text!
            invitation.confirmed = 0
            invitation.sendername = self.configManager.selfName
            invitation.receivername = self.iCloudName.text!
            
            dataManager.cdAddInvitation(invitation)
            
            dataManager.inviteToShare(self.iCloudIdVar, receiverName: self.iCloudNameVar)
            
            dataManager.subscribeOnResponse()
            dataManager.subscribeOnInvitations()
            
        }
        if(shareSwitchVar) {
            configManager.plistItems.setValue(1, forKey: "sharingEnabled")
            configManager.sharingEnabled = 1
            dataManager.shareEverythingForRecordId(self.myICloudVar)
            dataManager.subscribeOnInvitations()
            dataManager.subscribeOnItems(self.myICloudVar)
        }
        else {
            configManager.plistItems.setValue(0, forKey: "sharingEnabled")
            configManager.sharingEnabled = 0
            dataManager.ckRemoveAllRecords(self.myICloudVar)
        }
        configManager.writeConfigPlist()
        configManager.writeKeyStore()
        //dataManager.shareEverythingForRecordId(self.myICloudVar)
            
        self.performSegueWithIdentifier("unwindFromConfig", sender: self)
        
        
    }
    
    func showInviteList(invitation: InvitationObject) {
        
        if(invitation.sendername != "") {
            _ = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_main_queue(), {
            
                self.showInviteList.hidden = false
                self.findView.hidden = true
                self.nameSubscription.text = invitation.sendername
                if(invitation.confirmed > 0) {
                    self.cancelSubscription.setImage(UIImage(named: "shareConfirmedButton"), forState: UIControlState.Normal)
                }
            
            
            })
        } else {
            dataManager.ckFetchInvitations(showInviteListFromCloudKit)
            //self.showInviteList.hidden = true
        }
        
        
        
    }
    
    func showInviteListFromCloudKit(sender: String) -> Void {
        
        if(sender != "") {
            _ = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_main_queue(), {
                
                self.showInviteList.hidden = false
                self.findView.hidden = true
                self.nameSubscription.text = sender

                
                
            })
        } else {
            self.showInviteList.hidden = true
        }
        
    }
    
    @IBAction func findICloudContact(sender: AnyObject) {
        
        let iCloudName: String = iCloudEmail.text!
        let container: CKContainer = CKContainer.defaultContainer()
        
        let spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        
        iCloudEmail.leftView = spinner
        spinner.startAnimating()

        container.discoverUserInfoWithEmailAddress(iCloudName, completionHandler:{ (userInfo: CKDiscoveredUserInfo?, error: NSError?) -> Void in
            
            if(userInfo != nil) {
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    // do some task
                    dispatch_async(dispatch_get_main_queue()) {
                        if let tmpUserInfo = userInfo {
                            self.iCloudId.text = tmpUserInfo.userRecordID!.recordName
                            self.iCloudIdVar = tmpUserInfo.userRecordID!.recordName
                            self.iCloudName.text = tmpUserInfo.displayContact?.givenName
                            self.iCloudLastname.text = tmpUserInfo.displayContact?.familyName
                            self.iCloudNameVar = (tmpUserInfo.displayContact?.givenName)! + " " + (tmpUserInfo.displayContact?.familyName)!
                            spinner.stopAnimating()
                            self.iCloudEmail.leftView = nil
                        
                            self.sendInvitationButton.enabled = true
                        }
                    }
                }

            }
            else {
                self.iCloudName.text = "Nothing found"
            }
        })
        
        
    }

    @IBAction func cancelSubscriptionAction(sender: AnyObject) {
        
        let invitation = dataManager.cdGetConfirmedInvitation()
        
        dataManager.cdRemoveInvitation()
        
        dataManager.ckRemoveInvitationSubscription(invitation.sender, receiver: invitation.receiver)
        
        self.showInviteList.alpha = 1.0
        //findView.hidden = true
        UIView.animateWithDuration(0.25, animations: {
            self.showInviteList.alpha = 0.0
            }, completion: {
                (value: Bool) in
                print(">>> Animation done.")
        })
        showInviteList.hidden = true
        
        self.findView.alpha = 0.0
        
        UIView.animateWithDuration(0.25, animations: {
            self.findView.alpha = 1.0
            }, completion: {
                (value: Bool) in
                print(">>> Animation done.")
        })
        findView.hidden = false
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
