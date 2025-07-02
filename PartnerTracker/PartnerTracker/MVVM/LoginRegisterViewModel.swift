//
//  LoginRegisterViewModel.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class LoginRegisterViewModel: ObservableObject {
    private var auth = Auth.auth()
    private var db = Firestore.firestore()
    
    @Published var isLoggedIn: Bool = false
    @Published var user: AppUser?
    @Published var isLoading: Bool = true 
    
    init() {
        
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isLoggedIn = user != nil
                self?.isLoading = false
                
                if let _ = user {
                    self?.fetchCurrentUser()
                } else {
                    self?.user = nil
                }
            }
        }
    }

    func register(email: String, password: String, name: String, surname: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Registrierung fehlgeschlagen: \(error.localizedDescription)")
                return
            }
            
            guard let self = self,
                  let firebaseUser = authResult?.user else { return }
            
            let appUser = AppUser(
                id: firebaseUser.uid,
                surname: surname,
                name: name,
                email: email
            )
            
            self.saveUserToFirestore(appUser)
        }
    }

    private func saveUserToFirestore(_ user: AppUser) {
        do {
            try db.collection("users").document(user.id).setData(from: user) { error in
                if let error = error {
                    print("Fehler beim Speichern des Users: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.user = user
                    }
                }
            }
        } catch {
            print("Fehler bei Serialisierung: \(error.localizedDescription)")
        }
    }

    func fetchCurrentUser() {
        guard let uid = auth.currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Fehler beim Laden des Benutzers: \(error.localizedDescription)")
                return
            }
            
            if let user = try? snapshot?.data(as: AppUser.self) {
                DispatchQueue.main.async {
                    self?.user = user
                }
            }
        }
    }

    func login(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                print("Login fehlgeschlagen: \(error.localizedDescription)")
                return
            }
            
        }
    }

    func signOut() {
        do {
            try auth.signOut()
            self.user = nil
           
        } catch {
            print("Fehler beim Ausloggen: \(error.localizedDescription)")
        }
    }
}
