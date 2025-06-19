//
//  LoginRegisterViewModel.swift
//  PartnerTracker
//
//  Created by Artur Günter on 17.06.25.
//
import FirebaseAuth
import FirebaseFirestore
import Combine

class LoginRegisterViewModel: ObservableObject {
    private var auth = Auth.auth()
    private var db = Firestore.firestore()

    @Published var user: AppUser?

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
                    print("Fehler beim Speichern des Users in Firestore: \(error.localizedDescription)")
                } else {
                    print("User erfolgreich in Firestore gespeichert.")
                    DispatchQueue.main.async {
                        self.user = user
                    }
                }
            }
        } catch {
            print("Serialisierungsfehler beim Speichern des Users: \(error.localizedDescription)")
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
        auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Login fehlgeschlagen: \(error.localizedDescription)")
                return
            }

            self?.fetchCurrentUser()
        }
    }

}

