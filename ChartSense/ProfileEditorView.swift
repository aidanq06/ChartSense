import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Image Section
                    ProfileImageSection(
                        profileImage: $profileImage,
                        showingImagePicker: $showingImagePicker
                    )
                    
                    // Profile Information
                    ProfileInformationSection(
                        name: $name,
                        email: $email,
                        bio: $bio
                    )
                    
                    // Save Button
                    SaveButton(
                        isSaving: $isSaving,
                        onSave: saveProfile
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(themeManager.isDarkMode ? AppTheme.dark.colors.background : AppTheme.light.colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveProfile()
                    }
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        if let user = authViewModel.currentUser {
            name = user.name
            email = user.email
            bio = "Financial enthusiast and ChartSense user"
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        // Simulate save operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Profile Image Section
struct ProfileImageSection: View {
    @Binding var profileImage: UIImage?
    @Binding var showingImagePicker: Bool
    @StateObject private var themeManager = ThemeManager.shared
    @ObservedObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(authViewModel.currentUser?.name.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // Edit Icon
                    Circle()
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        )
                        .offset(x: 35, y: 35)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Tap to change photo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.secondaryText : AppTheme.light.colors.secondaryText)
        }
    }
}

// MARK: - Profile Information Section
struct ProfileInformationSection: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var bio: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Name Field
            ProfileField(
                title: "Name",
                placeholder: "Enter your name",
                text: $name,
                icon: "person.fill"
            )
            
            // Email Field
            ProfileField(
                title: "Email",
                placeholder: "Enter your email",
                text: $email,
                icon: "envelope.fill",
                isEditable: false
            )
            
            // Bio Field
            ProfileField(
                title: "Bio",
                placeholder: "Tell us about yourself",
                text: $bio,
                icon: "text.quote",
                isMultiline: true
            )
        }
    }
}

// MARK: - Profile Field
struct ProfileField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    let isEditable: Bool
    let isMultiline: Bool
    
    @StateObject private var themeManager = ThemeManager.shared
    
    init(title: String, placeholder: String, text: Binding<String>, icon: String, isEditable: Bool = true, isMultiline: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isEditable = isEditable
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primary : AppTheme.light.colors.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
            }
            
            if isMultiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .disabled(!isEditable)
                    .lineLimit(3...6)
                    .padding(16)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(themeManager.isDarkMode ? AppTheme.dark.colors.primaryText : AppTheme.light.colors.primaryText)
                    .disabled(!isEditable)
                    .padding(16)
                    .background(themeManager.isDarkMode ? AppTheme.dark.colors.cardBackground : AppTheme.light.colors.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.isDarkMode ? AppTheme.dark.colors.border : AppTheme.light.colors.border, lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - Save Button
struct SaveButton: View {
    @Binding var isSaving: Bool
    let onSave: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: onSave) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isSaving ? "Saving..." : "Save Changes")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isSaving)
        .buttonStyle(PlainButtonStyle())
    }
} 