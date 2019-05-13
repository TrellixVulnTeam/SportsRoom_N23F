//
//  HomePageViewController.swift
//  SportsRoom
//
//  Created by Javier Xing on 2017-12-13.
//  Copyright © 2017 Javier Xing. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import XLPagerTabStrip
import MapKit
import ChameleonFramework


class HomePageViewController: ButtonBarPagerTabStripViewController, CLLocationManagerDelegate, SearchContainerProtocol{
    
    let locationManager: CLLocationManager = CLLocationManager()
    let dateFormatter = DateFormatter()
    var pulledData: Dictionary<String,Any> = [:]
    var currentUser: User?
    var customLocation: CLLocation?
    var customAddress: String?
    var searchRadius: Int?
    var joinedGamesVC: JoinedGameViewController?
    var ownedGamesVC: OwnedGameViewController?
    var searchBarVC: SearchContainerViewController?

//    var searchBarButton = UIBarButtonItem()
//    var profileButton = UIBarButtonItem()
    

    @IBOutlet weak var searchBarContainer: UIView!
    @IBOutlet weak var buttonBarViewTopConstraint: NSLayoutConstraint!

    
    @IBOutlet weak var containerViewTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        let profileImage = UIImage(named: "profile-1")
        let searchImage = UIImage(named: "searchlogo")
        let iconSize = CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30))
        let profileButton = UIButton(frame: iconSize)
        let searchButton = UIButton(frame: iconSize)
        profileButton.setBackgroundImage(profileImage, for: .normal)
        searchButton.setBackgroundImage(searchImage, for: .normal)
        let profileBarButton = UIBarButtonItem(customView: profileButton)
        let searchBarButton = UIBarButtonItem(customView: searchButton)
        profileButton.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
        searchButton.addTarget(self, action: #selector(showSearchBar), for: .touchUpInside)
        
        self.navigationItem.leftBarButtonItem = profileBarButton
        self.navigationItem.rightBarButtonItem = searchBarButton
        observeFireBase()
        createCurrentUser()
        configureView()
        setupDateFormatter()
        enableLocationServices()
        searchBarContainer.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if customAddress == nil || customLocation == nil {
            if let searchBar = searchBarVC {
                searchBar.searchLocationLabel.text = "Current Location"
                searchBar.dropDown.deselectRow(at: 1)
                searchBar.dropDown.selectRow(0)
            }
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "createGame", sender: self)
    }
    
    //Mark: - FireBase Methods
    
    func observeFireBase() {
        let childRef = Database.database().reference(withPath: "users/Jason")
        childRef.observe(DataEventType.value) { (snapshot) in
            let value = snapshot.value
            print("\(String(describing: value))")
        }
        childRef.removeAllObservers()
    }
    
    //Mark: - NavBar Button Methods
    @objc func showProfile() {
        performSegue(withIdentifier: "showProfile", sender: self)
    }
    
    deinit {
        print("Test")
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let child_1 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "joinedGame") as? JoinedGameViewController
        joinedGamesVC = child_1

        let child_2 = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "hostedGame") as? OwnedGameViewController
        ownedGamesVC = child_2
        
        return [child_1!, child_2!]
    }
    
    func configureView() {
        buttonBarView.backgroundColor = .flatNavyBlue
        settings.style.buttonBarItemBackgroundColor = .flatNavyBlue
        buttonBarView.selectedBar.backgroundColor = .flatYellow
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 14)
        settings.style.selectedBarHeight = 2.0
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarItemTitleColor = .white
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarLeftContentInset = 0
        settings.style.buttonBarRightContentInset = 0
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .white
            newCell?.label.textColor = .flatYellow
        }
    }
    
    func enableLocationServices() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self

        switch CLLocationManager.authorizationStatus() {
        case CLAuthorizationStatus.notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func createCurrentUser () {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!)
        ref.observe(.value) { (snapshot) in
            self.currentUser = User(snapshot: snapshot)
            self.joinedGamesVC?.gamesArrayDetails = [Game]()
            self.ownedGamesVC?.gamesArrayDetails = [Game]()
            self.getJoinedGames()
            self.getHostedGames()
        }
    }
    
    func setupDateFormatter() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
    }
    
    func getJoinedGames () {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!).child("joinedGames")
        
        ref.observeSingleEvent(of: .value) {(snapshot) in
//            quick fix for strange bug where sometimes the data pulled down is duplicated
            self.joinedGamesVC?.gamesArrayDetails.removeAll()
            
            let value = snapshot.value as? [String:String] ?? [:]
            let gamesArrayID = Array(value.keys)
            for id in gamesArrayID {
                let ref = Database.database().reference().child("games").child(id)
                ref.observeSingleEvent(of: .value) { (snapshot) in
                    let game = Game(snapshot: snapshot)
                    let gameDate = self.dateFormatter.date(from: game.date)
                    if gameDate! < Date() {
                        let gameKey = game.gameID
                        let refUser = Database.database().reference().child("users").child(userID!).child("joinedGames")
                        refUser.child(gameKey).removeValue()
                        let refGame = Database.database().reference().child("games").child(gameKey).child("joinedPlayers")
                        refGame.child(userID!).removeValue()
                    }
                    else {
                        self.joinedGamesVC?.gamesArrayDetails.append(game)
                    }
                }
            }
        }
    }
    
    func getHostedGames () {
        let userID = Auth.auth().currentUser?.uid
        let ref = Database.database().reference().child("users").child(userID!).child("hostedGames")
        
        ref.observeSingleEvent(of: .value) {(snapshot) in
//            quick fix for strange bug where sometimes the data pulled down is duplicated
            self.ownedGamesVC?.gamesArrayDetails.removeAll()
            let value = snapshot.value as? [String:String] ?? [:]
            let gamesArrayID = Array(value.keys)
            for id in gamesArrayID {
                let ref = Database.database().reference().child("games").child(id)
                ref.observeSingleEvent(of: .value) { (snapshot) in
                    let game = Game(snapshot: snapshot)
                    
                    let gameDate = self.dateFormatter.date(from: game.date)
                    if gameDate! < Date() {
                        let gameKey = game.gameID
                        let refGame = Database.database().reference().child("games").child(gameKey)
                        refGame.child("sport").removeValue()

                        refGame.updateChildValues(["completedGameType" : "\(game.sport)"])
                        let refUserHosted = Database.database().reference().child("users").child(userID!).child("hostedGames")
                        refUserHosted.child(gameKey).removeValue()
                    }
                    else{
                        self.ownedGamesVC?.gamesArrayDetails.append(game)
                    }
                }
            }
        }
    }
    
    @objc func showSearchBar () {
        if searchBarContainer.isHidden == true {
            searchBarContainer.isHidden = false
            buttonBarViewTopConstraint.constant = searchBarContainer.frame.height + 0.5
            containerViewTopConstraint.constant += searchBarContainer.frame.height + 0.5
            //        searchBar?.becomeFirstResponder()
            searchBarVC?.searchBar.becomeFirstResponder()
        }
        else{
            close()
        }
    }
    
    func close() {
        searchBarContainer.isHidden = true
        buttonBarViewTopConstraint.constant = 0.5
        containerViewTopConstraint.constant -= searchBarContainer.frame.height + 0.5
    }
    
    func search() {
        performSegue(withIdentifier: "searchGame", sender: self)
    }
    
    
    func searchCurrentLocation() {
        customLocation = nil
        customAddress = nil
    }
    
    func chooseSearchLocation() {
        performSegue(withIdentifier: "searchLocation", sender: self)
    }
    
    @IBAction func unwindFromMap (sender: UIStoryboardSegue) {
        if sender.source is SetLocationViewController {
            if let senderVC = sender.source as? SetLocationViewController {
                customAddress = senderVC.addressString
                customLocation = CLLocation(latitude: senderVC.latitudeDouble, longitude: senderVC.longitudeDouble)
                searchBarVC?.searchLocationLabel.text = customAddress
            }
            if customAddress == "" || (customLocation?.coordinate.latitude == 0.0 && customLocation?.coordinate.longitude == 0.0) {
                searchBarVC?.searchLocationLabel.text = "Current Location"
                customAddress = nil
                customLocation = nil
            }
        }
    }
    
    @IBAction func unwindFromSearch (sender: UIStoryboardSegue){
    }
    
    @IBAction func unwindFromCreateGame (sender: UIStoryboardSegue){
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchGame" {
            let navController = segue.destination as! UINavigationController
            let searchController = navController.topViewController as! SearchResultsViewController
            
            searchController.searchedSport = searchBarVC?.searchBar.text
            searchController.currentUser = currentUser
            searchController.searchLocation = customLocation
            searchController.searchRadius = (currentUser?.settings?["radius"] as? Int) ?? 30000
            searchBarVC?.searchBar.text = ""
        }
        
        if segue.identifier == "searchLocation" {
            let navController = segue.destination as! UINavigationController
            let setLocationVC = navController.topViewController as! SetLocationViewController
            setLocationVC.gamePurpose = SetLocationViewController.Purpose.searchGame
        }
        
        if segue.identifier == "searchBar" {
            let searchContainerVC = segue.destination as! SearchContainerViewController
            searchContainerVC.searchDelegate = self
            searchBarVC = searchContainerVC
        }
        
        if segue.identifier == "showProfile" {
            let profileVC = segue.destination as! ProfileViewController
            profileVC.currentUser = currentUser
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }
}

