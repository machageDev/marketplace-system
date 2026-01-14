class AppConfig {
  //static const String baseUrl = 'http://192.168.100.188:8000';
  static const String baseUrl = 'https://marketplace-system-1.onrender.com';
  static const String paystackInitializeEndpoint = '/api/payment/initialize/';
  
  // You can add different environments
  static const String developmentBaseUrl = 'https://marketplace-system-1.onrender.com';
  static const String productionBaseUrl = 'https://marketplace-system-1.onrender.com';
  
  static String getBaseUrl() {
    // You can switch based on environment
    const bool isProduction = bool.fromEnvironment('dart.vm.product');
    return isProduction ? productionBaseUrl : developmentBaseUrl;
  }
}