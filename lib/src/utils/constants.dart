const String cashflowStorageKey = '@CASHFLOW_STORAGE_KEY';
const String tokenStorageKey = '@TOKEN_STORAGE_KEY';
const String loginVersionStorageKey = '@LOGIN_VERSION_STORAGE_KEY';
// Chave antiga, lida só para migrar a escolha feita na projeção.
const String projectionVersionStorageKey = '@PROJECTION_VERSION_STORAGE_KEY';
const String screensVersionStorageKey = '@SCREENS_VERSION_STORAGE_KEY';
const String themeV2StorageKey = '@THEME_V2_STORAGE_KEY';
const String urlApi = 'https://cashfloweb.azurewebsites.net/api';
// const String urlApi = 'http://172.31.31.1:56666/api';

class Routes {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String login = '/login';
  static const String householdExpenseList = '/household-expense-list';
  static const String householdExpenseDetail = '/household-expense-detail';
  static const String vehicleList = '/vehicle-list';
  static const String vehicleDetail = '/vehicle-detail';
  static const String fuelExpenseList = '/fuel-expense-list';
  static const String fuelExpenseDetail = '/fuel-expense-detail';
  static const String earningList = '/earning-list';
  static const String earningDetail = '/earning-detail';
  static const String recurringEarningList = '/recurring-earning-list';
  static const String recurringExpenseList = '/recurring-expense-list';
  static const String recurringDetail = '/recurring-detail';
  static const String paymentList = '/payment-list';
  static const String paymentDetail = '/payment-detail';
  static const String creditCardList = '/credit-card-list';
  static const String creditCardDetail = '/credit-card-detail';
  static const String remainingBalance = '/remaining-balance';
  static const String account = '/account';
  static const String glossary = '/glossary';
}
