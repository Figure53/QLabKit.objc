//
//  AppDelegate.swift
//  QLabKitSwiftDemo
//
//  Created by Douglas Heriot on 18/12/2015.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Cocoa

let REFRESH_INTERVAL: NSTimeInterval = 3.0 // seconds
let AUTOMATIC_CONNECTION = true
let QLAB_IP = "10.0.1.111"
let QLAB_PORT = 53000

// Using @objc(QLKAppDelegate) explicitly, to be compatible with the same nib file

@NSApplicationMain
@objc(QLKAppDelegate) class QLKAppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, QLKBrowserDelegate {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet var serversTableView: NSTableView!
    @IBOutlet var cuesTableView: NSTableView!
    @IBOutlet var connectionLabel: NSTextField!
    
    // dynamic makes this work with Cococa bindings
    dynamic var workspace: QLKWorkspace?
    var browser = QLKBrowser()
    var rows = [NSObject]()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cuesUpdated:", name: QLKWorkspaceDidUpdateCuesNotification, object: nil)
        
        if AUTOMATIC_CONNECTION {
            // Find QLab using continuously updating browser
            browser.delegate = self
            browser.start()
            browser.enableAutoRefreshWithInterval(REFRESH_INTERVAL)
        }
        else {
            let server = QLKServer(host: QLAB_IP, port: QLAB_PORT)
            server.name = "QLab"
            server.refreshWorkspacesWithCompletion({ (workspaces: [QLKWorkspace]) -> Void in
                self.rows.append(server)
                
                for workspace in server.workspaces {
                    self.rows.append(workspace)
                }
                
                self.serversTableView.reloadData()
            })
        }
        
        serversTableView.doubleAction = "connect:"
        serversTableView.target = self
    }
    
    
    // MARK: IBActions
    
    @IBAction func go(sender: AnyObject?) {
        workspace?.go()
    }
    
    @IBAction func stop(sender: AnyObject?) {
        workspace?.stopAll()
    }
    
    @IBAction func disconnect(sender: AnyObject?) {
        if let w = workspace {
            w.disconnect()
            workspace = nil
            
            connectionLabel.stringValue = ""
            cuesTableView.reloadData()
        }
    }
    
    @IBAction func connect(sender: AnyObject?) {
        disconnect(nil)
        
        let selectedRow = serversTableView.selectedRow
        
        // Make sure something is selected
        guard selectedRow != -1 else {
            return
        }
        
        workspace = rows[selectedRow] as? QLKWorkspace
        
        workspace?.connectWithPasscode(nil, completion: { (data: AnyObject!) -> Void in
            NSLog("[app delegate] workspace did connect");
            self.connectionLabel.stringValue = "Connected: \(self.workspace?.fullName ?? "")"
        })
    }
    
    
    // MARK: Updating
    
    @objc func cuesUpdated(notification: NSNotification) {
        cuesTableView.reloadData()
    }
    
    private func updateView() {
        rows = []
        
        for server in browser.servers {
            rows.append(server)
            
            for workspace in server.workspaces {
                rows.append(workspace)
            }
        }
        
        serversTableView.reloadData()
    }
    
    
    // MARK: QLKBrowserDelegate
    
    func browserDidUpdateServers(browser: QLKBrowser) {
        updateView()
    }
    
    func serverDidUpdateWorkspaces(server: QLKServer) {
        updateView()
    }
    
    
    // MARK: TableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView === serversTableView {
            return rows.count
        } else {
            return workspace?.firstCueList?.cues.count ?? 0
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellView = tableView.makeViewWithIdentifier("MainCell", owner: self) as! NSTableCellView
        
        if tableView === serversTableView {
            let obj = rows[row]
            
            if let server = obj as? QLKServer {
                cellView.textField?.stringValue = server.name.uppercaseString
            }
            else if let workspace = obj as? QLKWorkspace {
                cellView.textField?.stringValue = workspace.name
            }
        }
        else {
            guard let firstCueList = workspace?.firstCueList else {
                return cellView
            }
            
            let cue = firstCueList.cues[row]
            
            cellView.textField?.stringValue = tableColumn?.identifier == QLKOSCNumberKey ? cue.number : cue.displayName
        }
        
        return cellView
    }
    
    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return tableView === serversTableView && rows[row].isKindOfClass(QLKServer)
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return !self.tableView(tableView, isGroupRow: row)
    }
    
    // MARK: NSSplitViewDelegate
    
    func splitView(splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return splitView.subviews[0] != view
    }
}
