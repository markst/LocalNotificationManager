//
//  LocalNotificationScheduler.swift
//  Registration
//
//  Created by Cristian Madrid on 2/23/17.
//  Copyright © 2017 Unicred Brasil. All rights reserved.
//

import UserNotifications
import UIKit

public protocol LocalNotificationScheduler {
    init()
    func schedule(title: String, message: String, date: Date, repeats: Bool, categoryIdentifier: String)
    func schedule(title: String, message: String)
    func cleanNotifications(identifiers: [String]?)
}

extension LocalNotificationScheduler {
    public func schedule(title: String, message: String) {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .second, value: 10, to: Date()) ?? Date()
        schedule(title: title, message: message, date: date, repeats: false, categoryIdentifier: NSUUID().uuidString)
    }
}

public class LocalNotificationSchedulerFactory {
    static func instantiate() -> LocalNotificationScheduler {
        if #available(iOS 10, *) {
            return LocalNotificationSchedulerNewestiOS()
        }
        return LocalNotificationSchedulerLegacyiOS()
    }
}

@available(iOS 10.0, *)
public class LocalNotificationSchedulerNewestiOS: LocalNotificationScheduler {

    public required init() {
    }
    
    public func schedule(title: String, message: String, date: Date, repeats: Bool, categoryIdentifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.categoryIdentifier = categoryIdentifier
        content.sound = UNNotificationSound.default
        
        let center = UNUserNotificationCenter.current()
        center.add(generateNotificationRequest(content: content, date: date, repeats: repeats, categoryIdentifier: categoryIdentifier))
    }
    
    func generateNotificationRequest(content: UNMutableNotificationContent, date: Date, repeats: Bool, categoryIdentifier: String) -> UNNotificationRequest {
        let dateComponents: DateComponents
        if repeats {
            // Only supports repeating daily
            dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        } else {
            dateComponents = Calendar.current.dateComponents([.hour, .minute, .day], from: date)
        }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        return UNNotificationRequest(identifier: categoryIdentifier, content: content, trigger: trigger)
    }
    
    public func cleanNotifications(identifiers: [String]?) {
        if let identifiers = identifiers {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}

@available(iOS 9, *)
public class LocalNotificationSchedulerLegacyiOS: LocalNotificationScheduler {
    
    fileprivate var notifications = [UILocalNotification]()

    public required init() {
    }

    public func schedule(title: String, message: String, date: Date, repeats: Bool, categoryIdentifier: String) {
        schedule(title: title, message: message, date: date, repeatInterval: repeats ? .day : .init(rawValue: 0), categoryIdentifier: categoryIdentifier)
    }

    public func schedule(title: String, message: String, date: Date, repeatInterval: NSCalendar.Unit, categoryIdentifier: String) {
        let localNotification = UILocalNotification()
        notifications.append(localNotification)
        
        localNotification.fireDate = date
        localNotification.repeatInterval = repeatInterval
        localNotification.timeZone = TimeZone.current
        localNotification.alertTitle = title
        localNotification.alertBody = message
        localNotification.soundName = UILocalNotificationDefaultSoundName
        localNotification.category = categoryIdentifier
        UIApplication.shared.scheduleLocalNotification(localNotification)
    }
    
    public func cleanNotifications(identifiers: [String]?) {
        if identifiers == nil {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        for notification in notifications {
            UIApplication.shared.cancelLocalNotification(notification)
        }
    }
}
