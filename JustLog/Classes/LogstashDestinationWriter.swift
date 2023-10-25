//
//  LogstashDestinationWriter.swift
//  JustLog
//
//  Created by Luigi Parpinel on 25/05/21.
//

import Foundation

class LogstashDestinationWriter {

    private let socket: LogstashDestinationSocketProtocol

    private let shouldLogActivity: Bool
    
    init(socket: LogstashDestinationSocketProtocol, shouldLogActivity: Bool) {
        self.socket = socket
        self.shouldLogActivity = shouldLogActivity
    }
    
    func write(logs: [LogTag: LogContent],
               queue: DispatchQueue,
               completionHandler: @escaping ([LogTag: LogContent]?, Error?) -> Void) {
        
        guard !logs.isEmpty else {
            Self.printActivity("writeLogs() - nothing to write", shouldLogActivity: self.shouldLogActivity)
            completionHandler(nil, nil)
            return
        }

        let shouldLogActivity = self.shouldLogActivity
        socket.sendLogs(logs, transform: transformLogToData, queue: queue) { status in
            let unsentLog = logs.filter { status.keys.contains($0.key) }
            if unsentLog.isEmpty {
                Self.printActivity("🔌 <LogstashDestination>, did write tags: \(logs.keys)", shouldLogActivity: shouldLogActivity)
                completionHandler(nil, nil)
                return
            }
            
            /*
            if shouldLogActivity {
                status.forEach {
                    Self.printActivity("🔌 <LogstashDestination>, \($0.key) did error: \($0.value.localizedDescription)", shouldLogActivity: shouldLogActivity)
                }
            }
             completionHandler(unsentLog, status.first?.value)
            */
            
            completionHandler(unsentLog, nil)
        }
    }
    
    private func transformLogToData(_ dict: LogContent) -> Data {
        do {
            var data = try JSONSerialization.data(withJSONObject:dict, options:[])
            if let encodedData = "\n".data(using: String.Encoding.utf8) {
                data.append(encodedData)
            }
            return data
        } catch {
            Self.printActivity(error.localizedDescription, shouldLogActivity: self.shouldLogActivity)
            return Data()
        }
    }

    private static func printActivity(_ string: String, shouldLogActivity: Bool) {
        guard shouldLogActivity else { return }
        print(string)
    }
}
