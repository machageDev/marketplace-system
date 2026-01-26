class AppConfig {
  // Use Render URL for production
  //static const String baseUrl = 'https://marketplace-system-1.onrender.com';
 // static const String baseUrl = 'http://192.168.100.188:8000';
  // Local development URL (commented out)
  static const String baseUrl = 'https://marketplace-system-1.onrender.com';
  
  // Other endpoints
  static const String paystackInitializeEndpoint = '/api/payment/initialize/';
  
  // Environment URLs
  static const String developmentBaseUrl = 'https://marketplace-system-1.onrender.com';
  static const String productionBaseUrl = 'https://marketplace-system-1.onrender.com';
  
  static String getBaseUrl() {
    // Always return production URL for now
    return productionBaseUrl;
    
    // Alternative: Switch based on environment
    // const bool isProduction = bool.fromEnvironment('dart.vm.product');
    // return isProduction ? productionBaseUrl : developmentBaseUrl;
  }
}