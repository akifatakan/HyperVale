import SwiftUI
import Hyperswitch

// MARK: - 1. The Reusable Backend Model (Helper Class)
// This is kept internal to our new View
fileprivate class HyperswitchBackendModel: ObservableObject {

    // Parameters passed from the view
    private let publishableKey: String
    private let backendURL: String

    @Published var paymentSession: PaymentSession?
    @Published var paymentResult: PaymentSheetResult?
    @Published var isLoading = false
    @Published var serverError: String?

    // The model is initialized with the keys
    init(publishableKey: String, backendURL: String) {
        self.publishableKey = publishableKey
        self.backendURL = backendURL
    }

    @MainActor
    func preparePaymentSheet(amount: String, currency: String) {
        self.isLoading = true
        self.paymentSession = nil
        self.paymentResult = nil
        self.serverError = nil

        guard let url = URL(string: backendURL) else {
            self.serverError = "Invalid Backend URL"
            self.isLoading = false
            return
        }

        guard let amountInt = Int(amount) else {
            self.serverError = "Invalid amount. Must be a whole number (e.g., 6540 for $65.40)."
            self.isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "amount": amountInt,
            "currency": currency.uppercased()
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.serverError = "Connection Error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.serverError = "Server Error: Failed to create payment. Check server logs."
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let clientSecret = json["client_secret"] as? String
                else {
                    self.serverError = "Server Error: Failed to parse client_secret from response."
                    return
                }

                let session = PaymentSession(publishableKey: self.publishableKey)
                session.initPaymentSession(paymentIntentClientSecret: clientSecret)
                self.paymentSession = session
            }
        }
        task.resume()
    }

    @MainActor
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
        self.paymentSession = nil // Clear session after completion
    }
}

// MARK: - 2. The Public "Parametric View Element"
public struct HyperswitchPaymentView: View {

    // This model is now contained inside the view
    @StateObject private var model: HyperswitchBackendModel

    // State for the text fields
    @State private var amount = "6540"
    @State private var currency = "USD"

    /// Creates a self-contained payment view.
    /// - Parameters:
    ///   - publishableKey: Your public key from the Hyperswitch dashboard.
    ///   - backendURL: The URL for your server's `/create-payment-intent` endpoint.
    public init(publishableKey: String, backendURL: String) {
        _model = StateObject(wrappedValue: HyperswitchBackendModel(
            publishableKey: publishableKey,
            backendURL: backendURL
        ))
    }

    public var body: some View {
        Form {
            Section(header: Text("Payment Details")) {
                TextField("Amount (e.g., 6540)", text: $amount)
                    .keyboardType(.numberPad)
                TextField("Currency (e.g., USD)", text: $currency)
                    .autocapitalization(.allCharacters)
            }

            Section {
                Button("Prepare Payment") {
                    hideKeyboard()
                    model.preparePaymentSheet(amount: amount, currency: currency)
                }
                .disabled(model.isLoading)
            }

            if model.isLoading {
                ProgressView()
            } else if let paymentSession = model.paymentSession {
                // The Hyperswitch button appears
                PaymentSheet.PaymentButton(
                    paymentSession: paymentSession,
                    configuration: configuration(),
                    onCompletion: model.onPaymentCompletion
                ) {
                    Text("Pay Now")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }

            // Display results or errors
            Section(header: Text("Result")) {
                if let result = model.paymentResult {
                    displayPaymentResult(result)
                } else if let error = model.serverError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    Text("Please prepare a payment.")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // Helper function to show payment status
    @ViewBuilder
    private func displayPaymentResult(_ result: PaymentSheetResult) -> some View {
        switch result {
        case .completed:
            Text("Payment Complete! ✅")
                .foregroundColor(.green)
        case .failed(let error):
            Text("Payment Failed: \(error.localizedDescription) ❌")
                .foregroundColor(.red)
        case .canceled:
            Text("Payment Canceled. ⚠️")
                .foregroundColor(.orange)
        }
    }

    // Helper function for payment sheet config
    private func configuration() -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Demo App Inc."
        return config
    }
}

// Helper to dismiss the keyboard
#if canImport(UIKit)
extension View {
    fileprivate func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
