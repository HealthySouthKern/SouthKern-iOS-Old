//
//  ViewController.swift
//  SendBird-iOS
//
//  Created by Jed Kyung on 10/6/16.
//  Copyright © 2016 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class ViewController: UITableViewController, UITextFieldDelegate {
    
    // MARK: Properties
    var authUser: User?
    var displayName = "Anonymous"
    var ref: DatabaseReference!
    var sendbirdUser: SBDUser?
    fileprivate var _refHandle: DatabaseHandle!
    fileprivate var _authHandle: AuthStateDidChangeListenerHandle!
    
    // MARK: Outlets
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    
    //Sample UI
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var userIdLineView: UIView!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var nicknameLineView: UIView!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var versionLabel: UILabel!
    
    //Sample UI
    @IBOutlet weak var userIdLabelBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var nicknameLabelBottomMargin: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayVersion()
        configureView()
        //autoConnect()
        configureAuth()
        configureDatabase()
        
    }

    @IBAction func clickConnectButton(_ sender: AnyObject) {
        self.checkActiveUser(user: authUser)
        self.connect()
    }
    
    func displayVersion(){
        // Version
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")
        if path != nil {
            let infoDict = NSDictionary(contentsOfFile: path!)
            let sampleUIVersion = infoDict?["CFBundleShortVersionString"] as! String
            let version = String(format: "Sample UI v%@ / SDK v%@", sampleUIVersion, SBDMain.getSDKVersion())
            self.versionLabel.text = version
        }
    }
    
    func configureView(){
        // Setup Delegates for TextFields
        self.userIdTextField.delegate = self
        self.nicknameTextField.delegate = self
        
        self.userIdLabel.alpha = 0
        self.nicknameLabel.alpha = 0
        
        self.connectButton.setBackgroundImage(Utils.imageFromColor(color: Constants.connectButtonColor()), for: UIControlState.normal)
        self.indicatorView.hidesWhenStopped = true
    }
    
    func autoConnect(){
        // Check Saved user settings
        let userId = UserDefaults.standard.object(forKey: "sendbird_user_id") as? String
        let userNickname = UserDefaults.standard.object(forKey: "sendbird_user_nickname") as? String
        
        self.userIdLineView.backgroundColor = Constants.textFieldLineColorNormal()
        self.nicknameLineView.backgroundColor = Constants.textFieldLineColorNormal()
        
        if userId != nil && (userId?.count)! > 0 {
            self.userIdLabelBottomMargin.constant = 0
            self.view.setNeedsUpdateConstraints()
            self.userIdLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        if userNickname != nil && (userNickname?.count)! > 0 {
            self.nicknameLabelBottomMargin.constant = 0
            self.view.setNeedsUpdateConstraints()
            self.nicknameLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        self.userIdTextField.text = userId
        self.nicknameTextField.text = userNickname
        
        self.indicatorView.hidesWhenStopped = true
        
        self.userIdTextField.addTarget(self, action: #selector(userIdTextFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        self.nicknameTextField.addTarget(self, action: #selector(nicknameTextFieldDidChange(sender:)), for: UIControlEvents.editingChanged)
        
        if userId != nil && (userId?.count)! > 0 && userNickname != nil && (userNickname?.count)! > 0 {
            self.connect()
        }
    }
    
    // MARK: Config
    
    func configureAuth() {
        let provider: [FUIAuthProvider] = [FUIGoogleAuth()]
        FUIAuth.defaultAuthUI()?.providers = provider
        
        // listen for changes in the authorization state
        _authHandle = Auth.auth().addStateDidChangeListener { (auth: Auth, user: User?) in
            // Do the Dew
            
            self.checkActiveUser(user: user)
        }
    }
    
    deinit {
        Auth.auth().removeStateDidChangeListener(_authHandle)
    }
    
    // MARK: Sign In and Out
    
    func signedInStatus(isSignedIn: Bool) {
        //connectButton.isHidden = isSignedIn
        //connectButton.isHidden = !isSignedIn
        signOutButton.isHidden = !isSignedIn
       
        if isSignedIn {
            // remove background blur (will use when showing image messages)
            //Configure Stuff
        }
    }
    
    func loginSession() {
        let authViewController = FUIAuth.defaultAuthUI()!.authViewController()
        present(authViewController, animated: true, completion: nil)
    }
    
    // MARK: Configure Database
    func configureDatabase(){
        ref = Database.database().reference()
        // listen for new messages in the firebase database
      
    }
    
    // MARK: isActiveUser
    func checkActiveUser(user: User?){
        // check if there is a current user
        if let activeUser = user {
            // check if the current app user is the current FIRUser
            if self.authUser != activeUser {
                self.authUser = activeUser
                self.signedInStatus(isSignedIn: true)
                // let name = user!.email!.components(separatedBy: "@")[0]
                self.userIdTextField.text = user!.email
                self.nicknameTextField.text = user!.displayName
                
            }
        } else {
            // user must sign in
            self.signedInStatus(isSignedIn: false)
            self.loginSession()
        }
    }
    
    // MARK: Connect to Sendbird
    func connect() {
        
        self.userIdTextField.isEnabled = false
        self.nicknameTextField.isEnabled = false
        
        self.indicatorView.startAnimating()
        
        let uuid = authUser?.uid
        let sendBirdToken = getSendBirdToken(uuid: uuid!)
        
        SBDMain.connect(withUserId: (self.authUser?.email!)!,  accessToken: sendBirdToken, completionHandler: { (user, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.userIdTextField.isEnabled = true
                        self.nicknameTextField.isEnabled = true
                        
                        self.indicatorView.stopAnimating()
                    }
                    
                    let vc = UIAlertController(title: Bundle.sbLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                    let closeAction = UIAlertAction(title: Bundle.sbLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
                    vc.addAction(closeAction)
                    DispatchQueue.main.async {
                        self.present(vc, animated: true, completion: nil)
                    }
                    
                    return
                }
                
                if SBDMain.getPendingPushToken() != nil {
                    SBDMain.registerDevicePushToken(SBDMain.getPendingPushToken()!, unique: true, completionHandler: { (status, error) in
                        if error == nil {
                            if status == SBDPushTokenRegistrationStatus.pending {
                                print("Push registeration is pending.")
                            }
                            else {
                                print("APNS Token is registered.")
                            }
                        }
                        else {
                            print("APNS registration failed.")
                        }
                    })
                }
            
            SBDMain.updateCurrentUserInfo(withNickname: self.authUser?.displayName, profileUrl: nil, completionHandler: { (error) in
                    DispatchQueue.main.async {
                        self.userIdTextField.isEnabled = true
                        self.nicknameTextField.isEnabled = true
                        
                        self.indicatorView.stopAnimating()
                    }
                    
                    // Something Broke
                    if error != nil {
                        let vc = UIAlertController(title: Bundle.sbLocalizedStringForKey(key: "ErrorTitle"), message: error?.domain, preferredStyle: UIAlertControllerStyle.alert)
                        let closeAction = UIAlertAction(title: Bundle.sbLocalizedStringForKey(key: "CloseButton"), style: UIAlertActionStyle.cancel, handler: nil)
                        vc.addAction(closeAction)
                        DispatchQueue.main.async {
                            self.present(vc, animated: true, completion: nil)
                        }
                        
                        SBDMain.disconnect(completionHandler: {
                            
                        })
                        
                        return
                    }
                    
                    //Nothing failed Get
                    self.sendbirdUser = SBDMain.getCurrentUser()
                    // Sets UserDefaults
                    UserDefaults.standard.set(self.sendbirdUser?.userId, forKey: "sendbird_user_id")
                    UserDefaults.standard.set(self.sendbirdUser?.nickname, forKey: "sendbird_user_nickname")
                })
                
                DispatchQueue.main.async {
                    let vc = MenuViewController(nibName: "MenuViewController", bundle: Bundle.main)
                    self.present(vc, animated: false, completion: nil)
                }
            })
        
    }
    
    func getSendBirdToken(uuid: String) -> String{
        print(uuid)
        return ""
    }
    
    // MARK: Actions
    
    @IBAction func showLoginView(_ sender: AnyObject) {
        loginSession()
    }
    
    @IBAction func signOut(_ sender: UIButton) {
        
        self.userIdTextField.text = ""
        self.nicknameTextField.text = ""
        
        do {
            
            try Auth.auth().signOut()
        } catch {
            print("unable to sign out: \(error)")
        }
    }

    func userIdTextFieldDidChange(sender: UITextField) {
        if sender.text?.count == 0 {
            self.userIdLabelBottomMargin.constant = -12
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.1, animations: { 
                self.userIdLabel.alpha = 0
                self.view.layoutIfNeeded()
            })
        }
        else {
            self.userIdLabelBottomMargin.constant = 0
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.2, animations: {
                self.userIdLabel.alpha = 1
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func nicknameTextFieldDidChange(sender: UITextField) {
        if sender.text?.count == 0 {
            self.nicknameLabelBottomMargin.constant = -12
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.1, animations: {
                self.nicknameLabel.alpha = 0
                self.view.layoutIfNeeded()
            })
        }
        else {
            self.nicknameLabelBottomMargin.constant = 0
            self.view.setNeedsUpdateConstraints()
            UIView.animate(withDuration: 0.2, animations: {
                self.nicknameLabel.alpha = 1
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }

    // MARK: UITextFieldDelegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == self.userIdTextField {
            self.userIdLineView.backgroundColor = Constants.textFieldLineColorSelected()
        }
        else if textField == self.nicknameTextField {
            self.nicknameLineView.backgroundColor = Constants.textFieldLineColorSelected()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == self.userIdTextField {
            self.userIdLineView.backgroundColor = Constants.textFieldLineColorNormal()
        }
        else if textField == self.nicknameTextField {
            self.nicknameLineView.backgroundColor = Constants.textFieldLineColorNormal()
        }
    }
}
