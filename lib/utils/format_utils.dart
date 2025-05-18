String formatPrice(double price) {
  if (price == 0) return '0 đ';
  
  // Convert to integer if the decimal part is 0
  int priceInt = price.toInt();
  
  // Convert to string and split into groups of 3 digits from right to left
  String priceStr = priceInt.toString();
  String result = '';
  
  for (int i = priceStr.length - 1, count = 0; i >= 0; i--, count++) {
    if (count > 0 && count % 3 == 0) {
      result = '.' + result;
    }
    result = priceStr[i] + result;
  }
  
  return '$result đ';
} 