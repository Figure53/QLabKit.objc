//
//  QLKCueListDelegate.swift
//  QLabKit
//
//  Created by Richard Williamson on 25/02/2017.
//  Copyright © 2017 Figure 53. All rights reserved.
//

import Cocoa

let QLKNotifyCueListSelected = "QLKCueListSelected"

class QLKCueListDelegate: NSObject, NSTableViewDelegate, NSTableViewDataSource {

  var workspace: QLKWorkspace?
  
  //MARK: - NSTableViewDelegate
  func numberOfRows(in tableView: NSTableView) -> Int
  {
    guard let list = workspace?.root.cues else { return 0 }
    
    return list.count - 1; //active cues doesn't want to be listed, is it safe to assume this is always at the end?
    
  }
  
//  - (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
//  {
//  return self.rows.count;
//  }
  func tableView(_ tableView: NSTableView,
                          viewFor tableColumn: NSTableColumn?,
                          row: Int) -> NSView?
  {
    guard let q = self.workspace?.root.cues[row] else { return nil }
    
    guard let cellView = tableView.make(withIdentifier: "MainCell", owner: self) as? NSTableCellView else { print("error"); return nil; }
    cellView.textField?.stringValue = q.name!
    
    return cellView
    
  }
  
  func tableViewSelectionDidChange(_ notification: Notification)
  {
    
    guard let table = notification.object as? NSTableView else { return }
    let index = table.selectedRow
    
    NotificationCenter.default.post(name: Notification.Name(QLKNotifyCueListSelected), object: self.workspace?.root.cues[index])
  
  }
//  - (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//  {
//  NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
//  
//  
//  id obj = self.rows[row];
//  cellView.textField.stringValue = ([obj isKindOfClass:[QLKServer class]]) ? [(QLKServer *)obj name].uppercaseString : [(QLKWorkspace *)obj name];
//  
//  
//  return cellView;
//  }
  
//  - (BOOL) tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
//  {
//  return [self.rows[row] isKindOfClass:[QLKServer class]];
//  }
//  
//  - (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
//  {
//  return ![self tableView:tableView isGroupRow:row];
//  }
  

}
