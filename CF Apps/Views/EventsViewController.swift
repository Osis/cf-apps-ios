import Foundation
import UIKit
import SwiftyJSON
import CFoundry

class EventsViewController: UITableViewController {
    var appGuid: String?
    var events = [CFEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentOffset.y -= self.refreshControl!.frame.size.height
        self.refreshControl!.beginRefreshing()
        self.refreshControl!.sendActions(for: UIControlEvents.valueChanged)
    }
    
    func fetchEvents() {
        setRefreshTitle("Fetching Events")
        
        CFApi.events(appGuid: self.appGuid!) { events, error in
            if let e = error {
                print(e.localizedDescription)
            }
            
            if let events = events {
                self.handleEventsRequest(events)
            }
        }
    }
    
    func handleEventsRequest(_ events: [CFEvent]) {
        for e in events {
            if let _ = e.readableType() {
                self.events.append(e)
            }
        }
        
        self.refreshControl!.endRefreshing()
        tableView.reloadData()
        setRefreshTitle("Refresh Events")
    }
    
    @IBAction func refresh(_ sender: AnyObject) {
        fetchEvents()
    }
    
    func setRefreshTitle(_ title: String) {
        DispatchQueue.main.async {
            self.refreshControl!.attributedTitle = NSAttributedString(string: title)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[indexPath.item]
        
        if let type = event.readableType() {
            switch type {
            case "operation":
                return operationalEventCell(event)
            case "update":
                return attributeEventCell(event)
            default:
                return crashEventCell(event)
            }
        }
        
        return event.isOperationalEvent() ? operationalEventCell(event) : attributeEventCell(event)
    }
    
    func operationalEventCell(_ event: CFEvent) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "OperationEventCell")
        

        let dateLabel = cell!.viewWithTag(1) as! UILabel
        dateLabel.text = formattedDate(timestamp: event.timestamp)
        
        let stateLabel = cell!.viewWithTag(2) as! UILabel
        stateLabel.text = event.requestedState!
        
        let stateImg = cell!.viewWithTag(3) as! UIImageView
        stateImg.image = UIImage(named: event.requestedState!.localizedLowercase)
        
        return cell!
    }
    
    func attributeEventCell(_ event: CFEvent) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "AttributeEventCell")
        
        let dateLabel = cell!.viewWithTag(1) as! UILabel
        dateLabel.text = formattedDate(timestamp: event.timestamp)
        
        let descriptionLabel = cell?.viewWithTag(2) as! UILabel
        descriptionLabel.text = event.attributeSummary()
        
        return cell!
    }
    
    func crashEventCell(_ event: CFEvent) ->  UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "CrashEventCell")
        
        let dateLabel = cell!.viewWithTag(1) as! UILabel
        dateLabel.text = formattedDate(timestamp: event.timestamp)
        
        let reasonLabel = cell!.viewWithTag(2) as! UILabel
        reasonLabel.text = event.reason
        
        let descriptionLabel = cell!.viewWithTag(3) as! UILabel
        descriptionLabel.text = event.exitDescription
        
        return cell!
    }
    
    func formattedDate(timestamp: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let date = dateFormatter.date(from: timestamp)
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        return dateFormatter.string(from: date!)
    }
}
