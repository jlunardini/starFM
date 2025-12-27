//
//  LoginView.swift
//  starFM
//
//  Login screen for Last.fm authentication.
//  Prompts for username and password, then authenticates with the API.
//

import SwiftUI

/// Login screen with username/password fields.
///
/// On successful authentication, stores the session key and username
/// in @AppStorage, which causes RootView to switch to RecentTracksView.
struct LoginView: View {

    // MARK: - Persisted State (shared with RootView)

    /// Stores the username after successful login
    @AppStorage("lastfm_username") private var storedUsername: String = ""

    /// Stores the session key after successful login
    @AppStorage("lastfm_sessionKey") private var storedSessionKey: String = ""

    // MARK: - Local State

    /// Username input field value
    @State private var username: String = ""

    /// Password input field value
    @State private var password: String = ""

    /// Whether we're currently authenticating
    @State private var isLoading: Bool = false

    /// Error message to display, if any
    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // App title
            header

            // Username and password fields
            inputFields

            // Login button
            loginButton

            Spacer()
        }
        .padding()
        // Error alert
        .alert("Login Failed", isPresented: showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    // MARK: - Subviews

    /// App title and subtitle
    private var header: some View {
        VStack(spacing: 8) {
            Text("starFM")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Rate your Last.fm tracks")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }

    /// Username and password text fields
    private var inputFields: some View {
        VStack(spacing: 16) {
            TextField("Last.fm Username", text: $username)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
                .autocapitalization(.none)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
        }
        .padding(.horizontal)
    }

    /// Login button with loading state
    private var loginButton: some View {
        Button {
            Task {
                await login()
            }
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign In")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || username.isEmpty || password.isEmpty)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties

    /// Binding to control error alert visibility
    private var showingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Methods

    /// Attempts to authenticate with Last.fm.
    ///
    /// On success, stores credentials in @AppStorage which triggers
    /// RootView to switch to the main app view.
    private func login() async {
        isLoading = true

        // Clear any previous error
        errorMessage = nil

        do {
            // Call the Last.fm API to authenticate
            let sessionKey = try await LastFMService.shared.authenticate(
                username: username,
                password: password
            )

            // Success! Store credentials
            // Setting these causes RootView to re-render and show RecentTracksView
            storedSessionKey = sessionKey
            storedUsername = username

        } catch {
            // Show error to user
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}

