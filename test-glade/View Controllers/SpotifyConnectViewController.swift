//
//  SpotifyConnectViewController.swift
//  test-glade
//
//  Created by Allen Gu on 10/11/20.
//

import UIKit
import Alamofire
import Firebase
import CodableFirebase
// https://github.com/alickbass/CodableFirebase

class SpotifyConnectViewController: UIViewController, SPTSessionManagerDelegate {

    @IBOutlet weak var verticalStack: UIStackView!
    @IBOutlet weak var gladeNameLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
        
    var configuration = SPTConfiguration(clientID: Constants.clientID, redirectURL: Constants.redirectURI)

    var ref: DatabaseReference = Database.database().reference()
    
    lazy var sessionManager: SPTSessionManager = {
        if let tokenSwapURL = Constants.tokenSwapURL,
           let tokenRefreshURL = Constants.tokenRefreshURL {
            self.configuration.tokenSwapURL = tokenSwapURL
            self.configuration.tokenRefreshURL = tokenRefreshURL
          // self.configuration.playURI = ""
        }
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupItems()
    }
    
    func setupItems() {
        // Vertical Stack
        verticalStack.spacing = 20
        
        // Glade
        gladeNameLabel.text = "Glade"
        //gladeNameLabel.textColor
        gladeNameLabel.font = UIFont.boldSystemFont(ofSize: 72)
        gladeNameLabel.textAlignment = .center
        gladeNameLabel.numberOfLines = 0
        
        // Connect Button
        connectButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        connectButton.setTitleColor(UIColor.systemGreen, for: .normal)
        
        // Next Button
        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(UIColor.systemGreen, for: .normal)
        nextButton.titleLabel!.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        nextButton.titleLabel!.textAlignment = .right
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Success:", session)
        
        var username: String?
        
        // Request account info
        print("\nAccount Info Request...")
        let spotifyAccessToken = session.accessToken
        let spotifyRefreshToken = session.refreshToken
        let headers: HTTPHeaders = [.accept("application/json"), .contentType("application/json"), .authorization(bearerToken: spotifyAccessToken)]
        let request = AF.request("https://api.spotify.com/v1/me", headers: headers)
        request.responseDecodable(of: User.self) { (response) in
            guard let user = response.value else {
                print("Failed to decode")
                return
            }
            print(user)
            username = user.id!
            let data = try! FirebaseEncoder().encode(user)
            self.ref.child("users/\(username!)").setValue(data)
            
            // Request user's top songs from Spotify
            self.getTopSongs(accessToken: spotifyAccessToken) { (result, songs) in
                if result {
                    for song in songs {
                        let data = try! FirebaseEncoder().encode(song)
                        self.ref.child("songs/\(song.id!)").setValue(data)
                        self.ref.child("songs/\(song.id!)/users/\(username!)").setValue(true)
                        self.ref.child("users/\(username!)/songs/\(song.id!)").setValue(data)
                    }
                    print("Success - request top songs")
                }
                else {
                    print("Failure - request top songs")
                }
            }
            
            // Request user's top artists from Spotify
            self.getTopArtists(accessToken: spotifyAccessToken) { (result, artists) in
                if result {
                    for artist in artists {
                        let data = try! FirebaseEncoder().encode(artist)
                        self.ref.child("artists/\(artist.id!)").setValue(data)
                        self.ref.child("artists/\(artist.id!)/users/\(username!)").setValue(true)
                        self.ref.child("users/\(username!)/artists/\(artist.id!)").setValue(data)
                    }
                    print("Success - request top artists")
                }
                else {
                    print("Failure - request top artists")
                }
            }
        }
        
//        // Get user data and store to Firebase
//        var username: String?
//        request.responseJSON { response in
//            switch response.result {
//            case let .success(value):
//                print(value)
//                let valueDict: NSDictionary = value as! NSDictionary
//                let storedDict: [String: Any] = ["display_name": valueDict["display_name"] as! String,
//                                                 "email": valueDict["email"] as! String,
//                                                 "id": valueDict["id"] as! String,
//                                                 "href": valueDict["href"] as! String,
//                                                 "images": valueDict["images"]!,
//                                                 "uri": valueDict["uri"] as! String]
//                self.ref.child("users/\(storedDict["id"]!)").setValue(storedDict)
//                username = storedDict["id"] as? String
//            case let .failure(error):
//                print(error)
//            }
//        }
        // Store tokens to Keychain
        try? Token.setToken(spotifyAccessToken, "Access Token")
        try? Token.setToken(spotifyRefreshToken, "Refresh Token")
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Failed with Error:", error)
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Renewed", session)
    }
    
    @IBAction func connectButtonTapped(_ sender: Any) {
        let scopes: SPTScope = [.userReadEmail, .userTopRead]

        if #available(iOS 11, *) {
            // Use this on iOS 11 and above to take advantage of SFAuthenticationSession
            sessionManager.initiateSession(with: scopes, options: .default)
        } else {
            // Use this on iOS versions < 11 to use SFSafariViewController
            sessionManager.initiateSession(with: scopes, options: .clientOnly, presenting: self)
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "toSchools", sender: self)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "toSchools" {
//            let schoolsVC: SchoolScrollViewController = segue.destination as! SchoolScrollViewController
//        }
//    }
    
    func getTopArtists(accessToken: String, completionHandler: @escaping (_ result: Bool, _ artists: [Artist]) -> ()) {
        var artists: [Artist] = []

        let headers: HTTPHeaders = [.accept("application/json"), .contentType("application/json"), .authorization(bearerToken: accessToken)]
        let parameters: Parameters = ["time_range": "short_term", "limit": 50]
        let request = AF.request("https://api.spotify.com/v1/me/top/artists", parameters: parameters, headers: headers)
        
        request.responseDecodable(of: ArtistResponse.self) { (response) in
            if let artistResponse = response.value {
                for artist in artistResponse.items! {
                    artists.append(artist)
                }
                completionHandler(true, artists)
            }
            else {
                print("Failed to decode artists")
                completionHandler(false, [])
            }

        }
    }
    
    func getTopSongs(accessToken: String, completionHandler: @escaping (_ result: Bool, _ artists: [Song]) -> ()) {
        var songs: [Song] = []

        let headers: HTTPHeaders = [.accept("application/json"), .contentType("application/json"), .authorization(bearerToken: accessToken)]
        let parameters: Parameters = ["time_range": "short_term", "limit": 50]
        let request = AF.request("https://api.spotify.com/v1/me/top/tracks", parameters: parameters, headers: headers)
        
        request.responseDecodable(of: SongResponse.self) { (response) in
            if let songResponse = response.value {
                for song in songResponse.items! {
                    songs.append(song)
                }
                completionHandler(true, songs)
            }
            else {
                print("Failed to decode songs")
                completionHandler(false, [])
            }

        }
    }
}
