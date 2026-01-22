class AppConfig {
  // Use Render URL for production
  //static const String baseUrl = 'https://marketplace-system-1.onrender.com';
  
  // Local development URL (commented out)
  static const String baseUrl = 'http://172.16.124.1:8000';
  
  // Other endpoints
  static const String paystackInitializeEndpoint = '/api/payment/initialize/';
  
  // Environment URLs
  static const String developmentBaseUrl = 'http://172.16.124.1:8000';
  static const String productionBaseUrl = 'http://172.16.124.1:8000';
  
  static String getBaseUrl() {
    // Always return production URL for now
    return productionBaseUrl;
    
    // Alternative: Switch based on environment
    // const bool isProduction = bool.fromEnvironment('dart.vm.product');
    // return isProduction ? productionBaseUrl : developmentBaseUrl;
  }
}