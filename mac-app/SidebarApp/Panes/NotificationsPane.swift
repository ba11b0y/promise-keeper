import SwiftUI

struct NotificationsPane: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notificationTitle = ""
    @State private var notificationBody = ""
    @State private var delaySeconds: Double = 1
    
    var body: some View {
        VStack(spacing: 20) {
            if !notificationManager.isPermissionGranted {
                VStack {
                    Text("Notifications Permission Required")
                        .font(.headline)
                    Button("Request Permission") {
                        notificationManager.requestPermission()
                    }
                }
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            
            Form {
                TextField("Notification Title", text: $notificationTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Notification Message", text: $notificationBody)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Text("Delay (seconds):")
                    Slider(value: $delaySeconds, in: 0...10, step: 0.5)
                    Text("\(delaySeconds, specifier: "%.1f")")
                }
                
                Button("Send Notification") {
                    guard !notificationTitle.isEmpty && !notificationBody.isEmpty else { return }
                    notificationManager.sendNotification(
                        title: notificationTitle,
                        body: notificationBody,
                        timeInterval: delaySeconds
                    )
                    
                    // Clear the fields after sending
                    notificationTitle = ""
                    notificationBody = ""
                    delaySeconds = 1
                }
                .disabled(!notificationManager.isPermissionGranted || notificationTitle.isEmpty || notificationBody.isEmpty)
            }
            .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PaneBackground())
    }
} 