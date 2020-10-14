//
//  SpotifyConnectViewController.swift
//  test-glade
//
//  Created by Allen Gu on 10/11/20.
//

import UIKit

class SpotifyConnectViewController: UIViewController, SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {

    // This configuration code probably shouldn't be here? Not sure
    private lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: Constants.clientID, redirectURL: Constants.redirectURI)
        
        // No clue why these lines are important, but the code breaks without them so... They're used for swapping/refreshing access tokens but idk why it's doing this on a localhost?
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()

    lazy var sessionManager: SPTSessionManager = {
        let sessionManager = SPTSessionManager(configuration: configuration, delegate: self)
        return sessionManager
    }()

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()
    
    var userData: [String: String] = [:]
    @IBOutlet var connectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Customized button move to custom view later
        connectButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        connectButton.setTitleColor(UIColor.white, for: .normal)
        connectButton?.layer.cornerRadius = (connectButton?.frame.size.height ?? 0)/2.0
        connectButton?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        connectButton.backgroundColor = UIColor(red: 47/255, green: 156/255, blue: 90/255, alpha: 0.8)
    }
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        let scope: SPTScope = [.appRemoteControl]

        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            sessionManager.initiateSession(with: scope, options: .clientOnly)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            sessionManager.initiateSession(with: scope, options: .clientOnly, presenting: self)
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Connected")
        appRemote.connect()
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Authorization failed")
    }
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Established connection")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Failed connection attempt")
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected with error")
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("Player state changed")
    }
    
}
