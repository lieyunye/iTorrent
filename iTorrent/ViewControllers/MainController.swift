//
//  ViewController.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

import UIKit

class MainController: ThemedUIViewController, UITableViewDataSource, UITableViewDelegate, ManagersUpdatedDelegate, ManagerStateChangedDelegate {
    @IBOutlet weak var tableView: ThemedUITableView!
    
    var managers : [[TorrentStatus]] = []
	var headers : [String] = []
    
    var topRightItemsCopy : [UIBarButtonItem]?
    var bottomItemsCopy : [UIBarButtonItem]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 104
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		tableView.updateTheme()
		navigationController?.toolbar.tintColor = navigationController?.navigationBar.tintColor
		
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
        tableView.reloadData()
		
        Manager.managersUpdatedDelegates.append(self)
		Manager.managersStateChangedDelegade.append(self)
        managerUpdated()
    
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Manager.managersUpdatedDelegates = Manager.managersUpdatedDelegates.filter({$0 !== (self as ManagersUpdatedDelegate)})
		Manager.managersStateChangedDelegade = Manager.managersStateChangedDelegade.filter({$0 !== (self as ManagerStateChangedDelegate)})
        
        if (tableView.isEditing) {
            editAction(navigationItem.leftBarButtonItem!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func managerUpdated() {
		//print("background test")
		var changed = false
		var oldManagers = managers
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
		if (oldManagers.count != managers.count) {
			changed = true
		} else {
			for i in 0 ..< managers.count {
				if (oldManagers[i].count != managers[i].count) {
					changed = true
					break
				}
			}
		}
		if (changed) {
			tableView.reloadData()
		} else {
			for cell in tableView.visibleCells {
				let cell = (cell as! TorrentCell)
				if let manager = Manager.getManagerByHash(hash: cell.manager.hash) {
					cell.manager = manager
					cell.update()
				}
			}
		}
    }
	
	func managerStateChanged(manager: TorrentStatus, oldState: String, newState: String) {
		managers.removeAll()
		managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &headers))
		tableView.reloadData()
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return headers.count
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return headers[section]
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if (!(view.subviews[0] is UIVisualEffectView)) {
			let blurEffect = UIBlurEffect(style: .light)
			let blurEffectView = UIVisualEffectView(effect: blurEffect)
			blurEffectView.frame = view.bounds
			blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
			
			let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
			view.tintColor = Themes.shared.theme[theme].tableHeaderColor
				
			if let header = view as? UITableViewHeaderFooterView {
				header.textLabel?.textColor = Themes.shared.theme[theme].mainText
			}
			
			view.addSubview(blurEffectView)
			view.insertSubview(blurEffectView, at: 0)
		} else {
			let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
			view.tintColor = Themes.shared.theme[theme].tableHeaderColor
			
			if let header = view as? UITableViewHeaderFooterView {
				header.textLabel?.textColor = Themes.shared.theme[theme].mainText
			}
		}
	}

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (tableView.isEditing) {
			navigationItem.rightBarButtonItem?.title = "Select All"
		}
        return managers[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TorrentCell
        cell.manager = managers[indexPath.section][indexPath.row]
        cell.update()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView.isEditing) {
            var b = true
            if let count = (tableView.indexPathsForSelectedRows?.count) {
                b = count > 0
                navigationItem.rightBarButtonItem?.title = "Deselect (\(count))"
            }
            for item in toolbarItems! {
                item.isEnabled = b
            }
            
        } else {
            let viewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "Detail") as! TorrentDetailsController
            viewController.managerHash = managers[indexPath.section][indexPath.row].hash
            
            if (!(splitViewController?.isCollapsed)!) {
    //            if (splitViewController?.viewControllers.count)! > 1, let nav = splitViewController?.viewControllers[1] as? UINavigationController {
    //                if let fileController = nav.topViewController
    //            }
                let navController = UINavigationController(rootViewController: viewController)
                navController.isToolbarHidden = false
                navController.navigationBar.tintColor = navigationController?.navigationBar.tintColor
                navController.toolbar.tintColor = navigationController?.navigationBar.tintColor
                splitViewController?.showDetailViewController(navController, sender: self)
            } else {
                splitViewController?.showDetailViewController(viewController, sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (tableView.isEditing) {
            var b = false
            if let count = (tableView.indexPathsForSelectedRows?.count) {
                b = count > 0
                navigationItem.rightBarButtonItem?.title = "Deselect (\(count))"
            } else {
                navigationItem.rightBarButtonItem?.title = "Select All"
            }
            for item in toolbarItems! {
                item.isEnabled = b
            }
        }
    }
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == .delete) {
			let message = managers[indexPath.section][indexPath.row].hasMetadata ? "Are you sure to remove " + managers[indexPath.section][indexPath.row].title + " torrent?" : "Are you sure to remove this magnet torrent?"
			let removeController = ThemedUIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
			let removeAll = UIAlertAction(title: "Yes and remove data", style: .destructive) { _ in
				self.removeTorrent(indexPath: indexPath, removeData: true)
			}
			let removeTorrent = UIAlertAction(title: "Yes but keep data", style: .default) { _ in
				self.removeTorrent(indexPath: indexPath)
			}
			let removeMagnet = UIAlertAction(title: "Remove", style: .destructive) { _ in
				self.removeTorrent(indexPath: indexPath, isMagnet: true)
			}
			let cancel = UIAlertAction(title: "Cancel", style: .cancel)
			if (!managers[indexPath.section][indexPath.row].hasMetadata) {
				removeController.addAction(removeMagnet)
			} else {
				removeController.addAction(removeAll)
				removeController.addAction(removeTorrent)
			}
			removeController.addAction(cancel)
			
			if (removeController.popoverPresentationController != nil) {
				removeController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
				removeController.popoverPresentationController?.sourceRect = (tableView.cellForRow(at: indexPath)?.bounds)!
				removeController.popoverPresentationController?.permittedArrowDirections = .left
			}
			
			present(removeController, animated: true)
		}
	}
	
	func removeTorrent(indexPath: IndexPath, isMagnet: Bool = false, removeData: Bool = false, visualOnly: Bool = false) {
		if (!visualOnly) {
			let manager = managers[indexPath.section][indexPath.row]
			remove_torrent(manager.hash, removeData ? 1 : 0)
			
			if (!(splitViewController?.isCollapsed)!) {
				splitViewController?.showDetailViewController(Utils.createEmptyViewController(), sender: self)
			}
			
			if (!isMagnet) {
				Manager.removeTorrentFile(hash: manager.hash)
				
				if (removeData) {
					do {
						try FileManager.default.removeItem(atPath: Manager.rootFolder + "/" + manager.title)
					} catch {
						print("MainController: removeTorrent()")
						print(error.localizedDescription)
					}
				}
			}
		}
		
		managers[indexPath.section].remove(at: indexPath.row)
		if (managers[indexPath.section].count > 0) {
			tableView.deleteRows(at: [indexPath], with: .automatic)
		} else {
			headers.remove(at: indexPath.section)
			managers.remove(at: indexPath.section)
			tableView.deleteSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .automatic)
		}
	}
    
    @IBAction func AddTorrentAction(_ sender: UIBarButtonItem) {
        let addController = ThemedUIAlertController(title: "Add from...", message: nil, preferredStyle: .actionSheet)
        
        let addURL = UIAlertAction(title: "URL", style: .default) { _ in
            let addURLController = ThemedUIAlertController(title: "Add from URL", message: "Please enter the existing torrent's URL below", preferredStyle: .alert)
            addURLController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "https://"
				let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
				textField.keyboardAppearance = Themes.shared.theme[theme].keyboardAppearence
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addURLController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				
				if let url = URL(string: textField.text!) {
					Downloader.load(url: url, to: URL(fileURLWithPath: Manager.configFolder+"/_temp.torrent"), completion: {
						let hash = String(validatingUTF8: get_torrent_file_hash(Manager.configFolder+"/_temp.torrent"))!
						if (hash == "-1") {
							let controller = ThemedUIAlertController(title: "Error has been occured", message: "Torrent file is broken or this URL has some sort of DDOS protection, you can try to open this link in Safari", preferredStyle: .alert)
							let safari = UIAlertAction(title: "Open in Safari", style: .default) { _ in
								UIApplication.shared.openURL(url)
							}
							let close = UIAlertAction(title: "Close", style: .cancel)
							controller.addAction(safari)
							controller.addAction(close)
							UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
							return
						}
						if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
							let controller = ThemedUIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash + "\" already exists in download queue", preferredStyle: .alert)
							let close = UIAlertAction(title: "Close", style: .cancel)
							controller.addAction(close)
							UIApplication.shared.keyWindow?.rootViewController?.present(controller, animated: true)
							return
						}
						let controller = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "AddTorrent")
						((controller as! UINavigationController).topViewController as! AddTorrentController).path = Manager.configFolder+"/_temp.torrent"
						self.present(controller, animated: true)
					}, errorAction: {
						let alertController = ThemedUIAlertController(title: "An error occurred", message: "Please, open this link in Safari, and send .torrent file from there", preferredStyle: .alert)
						let close = UIAlertAction(title: "Close", style: .cancel)
						alertController.addAction(close)
						self.present(alertController, animated: true)
					})
				} else {
					let alertController = ThemedUIAlertController(title: "Error", message: "Wrong link, check it and try again!", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					alertController.addAction(close)
					self.present(alertController, animated: true)
				}
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addURLController.addAction(ok)
            addURLController.addAction(cancel)
            
            self.present(addURLController, animated: true)
        }
        let addMagnet = UIAlertAction(title: "Magnet", style: .default) { _ in
            let addMagnetController = ThemedUIAlertController(title: "Add from magnet", message: "Please enter the magnet link below", preferredStyle: .alert)
            addMagnetController.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "magnet:"
				let theme = UserDefaults.standard.integer(forKey: UserDefaultsKeys.themeNum)
				textField.keyboardAppearance = Themes.shared.theme[theme].keyboardAppearence
				//textField.backgroundColor = Themes.shared.theme[theme].backgroundSecondary
				//textField.color
				//textField.textColor = Themes.shared.theme[theme].mainText
            })
            let ok = UIAlertAction(title: "OK", style: .default) { _ in
                let textField = addMagnetController.textFields![0]
                
                Utils.checkFolderExist(path: Manager.configFolder)
				let hash = String(validatingUTF8: get_magnet_hash(textField.text!))
				if (Manager.torrentStates.contains(where: {$0.hash == hash})) {
					let alert = ThemedUIAlertController(title: "This torrent already exists", message: "Torrent with hash: \"" + hash! + "\" already exists in download queue", preferredStyle: .alert)
					let close = UIAlertAction(title: "Close", style: .cancel)
					alert.addAction(close)
					self.present(alert, animated: true)
				}
                
                Manager.addMagnet(textField.text!)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            addMagnetController.addAction(ok)
            addMagnetController.addAction(cancel)
            
            self.present(addMagnetController, animated: true)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        addController.addAction(addMagnet)
        addController.addAction(addURL)
        addController.addAction(cancel)
		
		if (addController.popoverPresentationController != nil) {
			addController.popoverPresentationController?.barButtonItem = sender
			addController.popoverPresentationController?.permittedArrowDirections = .down
		}
        
        present(addController, animated: true)
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        let edit = !tableView.isEditing
        tableView.setEditing(edit, animated: true)
        sender.title = edit ? "Done" : "Edit"
        
        //NavBarItems
        var copy = navigationItem.rightBarButtonItems
        if (topRightItemsCopy == nil) {
            let item = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllItem(_:)))
            topRightItemsCopy = [item]
        }
        navigationItem.setRightBarButtonItems(topRightItemsCopy, animated: true)
        topRightItemsCopy = copy
        
        //ToolBarItems
        copy = toolbarItems
        if (bottomItemsCopy == nil) {
			let play = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(startSelectedOfTorrents(_:)))
            let pause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(pauseSelectedOfTorrents(_:)))
            let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(rehashSelectedTorrents(_:)))
            let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeSelectedTorrents(_:)))
            let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace , target: self, action: nil)
            bottomItemsCopy = [play, space, pause, space, refresh, space, space, space, space, trash]
        }
        setToolbarItems(bottomItemsCopy, animated: true)
        bottomItemsCopy = copy
        
        if (edit) {
            navigationItem.rightBarButtonItem?.title = "Select All"
            for item in toolbarItems! {
                item.isEnabled = false
            }
        }
    }
    
    @IBAction func sortAction(_ sender: UIBarButtonItem) {
		let sortingController = SortingManager.createSortingController(buttonItem: sender, applyChanges: {
			self.managers.removeAll()
			self.managers.append(contentsOf: SortingManager.sortTorrentManagers(managers: Manager.torrentStates, headers: &self.headers))
			self.tableView.reloadData();
		})
		present(sortingController, animated: true)
    }
    
    @objc func selectAllItem(_ sender: UIBarButtonItem) {
        var b = false
        if let count = tableView.indexPathsForSelectedRows?.count {
            b = count > 0
        }
        if (!b) {
            for i in 0 ..< tableView.numberOfSections {
                for j in 0 ..< tableView.numberOfRows(inSection: i) {
                    tableView.selectRow(at: IndexPath(row: j, section: i), animated: true, scrollPosition: .none)
                }
            }
            if let count = tableView.indexPathsForSelectedRows?.count {
                sender.title = "Deselect (\(count))"
                
                for item in toolbarItems! {
                    item.isEnabled = true
                }
            }
        } else {
            for i in 0 ..< tableView.numberOfSections {
                for j in 0 ..< tableView.numberOfRows(inSection: i) {
                    tableView.deselectRow(at: IndexPath(row: j, section: i), animated: true)
                }
            }
            for item in toolbarItems! {
                item.isEnabled = false
            }
            sender.title = "Select All"
        }
    }
	
	@objc func startSelectedOfTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			for indexPath in selected {
				start_torrent(managers[indexPath.section][indexPath.row].hash)
			}
		}
	}
	
	@objc func pauseSelectedOfTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			for indexPath in selected {
				stop_torrent(managers[indexPath.section][indexPath.row].hash)
			}
		}
	}
	
	@objc func rehashSelectedTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			var selectedHashes : [String] = []
			var message = ""
			for indexPath in selected {
				selectedHashes.append(managers[indexPath.section][indexPath.row].hash)
				message += "\n" + managers[indexPath.section][indexPath.row].title
			}
			
			message = message.trimmingCharacters(in: .whitespacesAndNewlines)
			
			let controller = ThemedUIAlertController(title: "This action will recheck the state of all downloaded files for torrents:", message: message, preferredStyle: .actionSheet)
			let hash = UIAlertAction(title: "Rehash", style: .destructive) { _ in
				for hash in selectedHashes {
					rehash_torrent(hash)
				}
			}
			let cancel  = UIAlertAction(title: "Cancel", style: .cancel)
			controller.addAction(hash)
			controller.addAction(cancel)
			
			if (controller.popoverPresentationController != nil) {
				controller.popoverPresentationController?.barButtonItem = sender
				controller.popoverPresentationController?.permittedArrowDirections = .down
			}
			
			present(controller, animated: true)
		}
	}
	
	@objc func removeSelectedTorrents(_ sender: UIBarButtonItem) {
		if let selected = tableView.indexPathsForSelectedRows {
			var selectedHashes : [String] = []
			for indexPath in selected {
				selectedHashes.append(managers[indexPath.section][indexPath.row].hash)
			}
			
			var message = ""
			for indexPath in selected {
				message += managers[indexPath.section][indexPath.row].title + "\n"
			}
			message = message.trimmingCharacters(in: .whitespacesAndNewlines)
			
			let removeController = ThemedUIAlertController(title: "Are you sure to remove \(selected.count) torrents?", message: message, preferredStyle: .actionSheet)
			let removeAll = UIAlertAction(title: "Yes and remove data", style: .destructive) { _ in
				for hash in selectedHashes {
					var index : IndexPath!
					for section in 0 ..< self.managers.count {
						for row in 0 ..< self.managers[section].count {
							if (self.managers[section][row].hash == hash) {
								index = IndexPath(row: row, section: section)
								break
							}
						}
					}
					if (index == nil) {
						print("Selected torrent dows not exists")
						continue
					}
					
					if (!self.managers[index.section][index.row].hasMetadata) {
						self.removeTorrent(indexPath: index, isMagnet: true)
					} else {
						self.removeTorrent(indexPath: index, removeData: true)
					}
				}
			}
			let removeTorrent = UIAlertAction(title: "Yes but keep data", style: .default) { _ in
				for hash in selectedHashes {
					var index : IndexPath!
					for section in 0 ..< self.managers.count {
						for row in 0 ..< self.managers[section].count {
							if (self.managers[section][row].hash == hash) {
								index = IndexPath(row: row, section: section)
								break
							}
						}
					}
					if (index == nil) {
						print("Selected torrent dows not exists")
						continue
					}
					
					if (!self.managers[index.section][index.row].hasMetadata) {
						self.removeTorrent(indexPath: index, isMagnet: true)
					} else {
						self.removeTorrent(indexPath: index)
					}
				}
			}
			let cancel = UIAlertAction(title: "Cancel", style: .cancel)
			
			removeController.addAction(removeAll)
			removeController.addAction(removeTorrent)
			removeController.addAction(cancel)
			
			if (removeController.popoverPresentationController != nil) {
				removeController.popoverPresentationController?.barButtonItem = sender
				removeController.popoverPresentationController?.permittedArrowDirections = .down
			}
			
			present(removeController, animated: true)
			
		}
		
		//let message = managers[indexPath.section][indexPath.row].hasMetadata ? "Are you sure to remove " + managers[indexPath.section][indexPath.row].title + " torrent?" : "Are you sure to remove this magnet torrent?"
		
	}
    
}

