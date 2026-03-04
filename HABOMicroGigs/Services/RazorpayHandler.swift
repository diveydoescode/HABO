// MARK: - RazorpayHandler.swift
import Foundation
import SwiftUI
import Combine
import Razorpay

class RazorpayHandler: NSObject, ObservableObject, RazorpayPaymentCompletionProtocolWithData {
    
    @Published var isPaying: Bool = false
    @Published var errorMessage: String? = nil
    
    private var razorpay: RazorpayCheckout? // Now optional, initialized at runtime
    
    var onSuccess: ((String, String, String) -> Void)?
    var onError: ((String) -> Void)?
    
    // We removed the init() block entirely! No hardcoded keys here.
    
    // ✅ Added keyId parameter here
    func startPayment(orderId: String, amountPaise: Int, keyId: String, appName: String = "HABO", email: String = "user@example.com", contact: String = "9999999999") {
        
        let options: [String: Any] = [
            "amount": amountPaise,
            "currency": "INR",
            "description": "Task Completion Payment",
            "order_id": orderId,
            "name": appName,
            "prefill": [
                "contact": contact,
                "email": email
            ],
            "theme": [
                "color": "#FF7300"
            ]
        ]
        
        DispatchQueue.main.async {
            self.isPaying = true
            self.errorMessage = nil
            
            // ✅ Initialize Razorpay dynamically using the key from the backend!
            self.razorpay = RazorpayCheckout.initWithKey(keyId, andDelegateWithData: self)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                
                self.razorpay?.open(options, displayController: rootVC)
                
            } else {
                self.isPaying = false
                self.errorMessage = "Could not present Razorpay screen."
            }
        }
    }
    
    // MARK: - Razorpay Callbacks
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        DispatchQueue.main.async {
            self.isPaying = false
            self.errorMessage = "Payment Failed: \(str)"
            self.onError?(str)
        }
    }
    
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        let paymentId = response?["razorpay_payment_id"] as? String ?? ""
        let orderId = response?["razorpay_order_id"] as? String ?? ""
        let signature = response?["razorpay_signature"] as? String ?? ""
        
        DispatchQueue.main.async {
            self.onSuccess?(paymentId, orderId, signature)
        }
    }
}
