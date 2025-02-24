import SwiftUI
import MessageUI

struct SettingsView: View {
    @State private var showingEmailAlert = false
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let supportEmail = "ottavio.buonomo@live.com"
    
    init() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Set orange color for navigation bar buttons
        UINavigationBar.appearance().tintColor = .orange
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        InfoView()
                    } label: {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                            
                            VStack(alignment: .leading) {
                                Text("About Recipe Book")
                                    .foregroundColor(.primary)
                                Text("Version \(appVersion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("APPLICATION")
                }
                
                Section {
                    Button {
                        showingEmailAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                            Text("Contact Support")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("SUPPORT")
                }
            }
            .navigationTitle("Settings")
            .alert("Contact Support", isPresented: $showingEmailAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please send an email to:\n\(supportEmail)")
            }
        }
        .accentColor(.orange)
    }
}

struct InfoView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    if let appIcon = UIImage(named: "AppIcon") {
                        Image(uiImage: appIcon)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(22)
                            .padding(.bottom, 8)
                    } else {
                        if let bundleIcon = Bundle.main.icon {
                            Image(uiImage: bundleIcon)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .cornerRadius(22)
                                .padding(.bottom, 8)
                        }
                    }
                    
                    Text("Recipe Book")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version \(appVersion)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section("About") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recipe Book is your personal cookbook assistant, helping you organize and manage your favorite recipes. Create, edit, and organize your recipes with ease.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(.vertical, 8)
            }
            
            Section("Features") {
                FeatureRow(icon: "book.fill", color: .blue, text: "Recipe Management")
                FeatureRow(icon: "leaf.fill", color: .green, text: "Ingredient Tracking")
                FeatureRow(icon: "timer", color: .orange, text: "Cooking Timer")
                FeatureRow(icon: "photo.fill", color: .purple, text: "Recipe Photos")
            }
            
            Section("Developer") {
                LabeledContent("Developer", value: "Ottavio Buonomo")
                LabeledContent("Copyright", value: "© 2025")
            }
        }
        .navigationTitle("Info")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .imageScale(.large)
                .frame(width: 30)
            Text(text)
                .padding(.leading, 4)
        }
        .padding(.vertical, 4)
    }
}

extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    @Environment(\.presentationMode) var presentation
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentation = presentation
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                 didFinishWith result: MFMailComposeResult,
                                 error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation,
                         result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["ottavio.buonomo@live.com"])
        vc.setSubject("Recipe Book Support")
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                              context: UIViewControllerRepresentableContext<MailView>) {
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
} 
