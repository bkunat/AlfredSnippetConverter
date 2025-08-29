import SwiftUI
import SnippetConverterCore

struct LocalizedAlertError: LocalizedError {
    let underlyingError: LocalizedError
    var errorDescription: String? {
        underlyingError.errorDescription
    }

    var recoverySuggestion: String? {
        underlyingError.recoverySuggestion
    }

    init?(error: Error?) {
        guard let localizedError = error as? LocalizedError else { return nil }
        underlyingError = localizedError
    }
}

extension View {
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedAlertError = LocalizedAlertError(error: error.wrappedValue)
        return alert(isPresented: .constant(localizedAlertError != nil), error: localizedAlertError) { _ in
            Button(buttonTitle) {
                error.wrappedValue = nil
            }
        } message: { error in
            Text(error.recoverySuggestion ?? "")
        }
    }
    
    func fileExistsAlert(
        error: Binding<Error?>, 
        onSaveAnyway: @escaping () -> Void
    ) -> some View {
        let errorDescription = error.wrappedValue?.localizedDescription ?? ""
        let isFileAlreadyExistsCase = errorDescription.contains("already exists")
        
        // Extract filename from error message if it's a file exists error
        let fileName: String? = {
            if isFileAlreadyExistsCase {
                // Try to extract filename from error message pattern: "filename already exists."
                let components = errorDescription.components(separatedBy: "\"")
                return components.count >= 2 ? NSString(string: components[1]).lastPathComponent : nil
            }
            return nil
        }()
        
        // Create a computed binding that excludes fileAlreadyExists errors
        let nonFileExistsError = Binding<Error?>(
            get: {
                isFileAlreadyExistsCase ? nil : error.wrappedValue
            },
            set: { newValue in
                if !isFileAlreadyExistsCase {
                    error.wrappedValue = newValue
                }
            }
        )
        
        return self
            .alert(
                "File Already Exists",
                isPresented: .constant(isFileAlreadyExistsCase)
            ) {
                Button("Cancel") {
                    error.wrappedValue = nil
                }
                Button("Save Anyway") {
                    error.wrappedValue = nil
                    onSaveAnyway()
                }
                .keyboardShortcut(.defaultAction)
            } message: {
                if let fileName = fileName {
                    Text("A file named \"\(fileName)\" already exists. Would you like to save with a different name?")
                } else {
                    Text("The file already exists. Would you like to save with a different name?")
                }
            }
            .errorAlert(error: nonFileExistsError)
    }
}
