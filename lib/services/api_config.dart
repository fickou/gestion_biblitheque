// Endpoints correspondant exactement à votre API PHP
import '/config/api_url.dart';
class Endpoints {
  // Authentification
  static const String login = 'login';
  
  // Utilisateurs
  static const String users = 'users';
  
  // Livres
  static const String books = 'books';
  
  // Emprunts
  static const String emprunts = 'emprunts';
  static const String userEmprunts = 'emprunts/user';
  static const String lateEmprunts = 'emprunts/late';
  static const String returnBook = 'return-book';
  
  // Réservations
  static const String reservations = 'reservations';
  static const String pendingReservations = 'reservations/pending';
  
  // Catégories
  static const String categories = 'categories';
  
  // Rôles
  static const String roles = 'roles';
  
  // Dashboard
  static const String dashboardStats = 'dashboard/stats';
  static const String topBooks = 'dashboard/top-books';
  static const String recentActivities = 'dashboard/recent-activities';
  static const String categoryStats = 'dashboard/category-stats';
  
  // Recherche
  static const String search = 'search';
}


class ApiConfig {
  
  static const String baseUrl = api;
  
  // CORRECTION CLÉ: Votre API attend le paramètre 'request' dans l'URL
  static String getUrl(String endpoint) {
    // Nettoyage de l'endpoint
    String cleanEndpoint = endpoint.replaceAll(RegExp(r'^/+|/+$'), '');
    return '$baseUrl/index.php?request=$cleanEndpoint';
  }
  
  // Méthodes avec URLs complètes CORRIGÉES
  static Uri getUsersUri() => Uri.parse(getUrl(Endpoints.users));
  static Uri getUserUri(String id) => Uri.parse(getUrl('${Endpoints.users}/$id'));
  
  static Uri getBooksUri() => Uri.parse(getUrl(Endpoints.books));
  static Uri getBookUri(String id) => Uri.parse(getUrl('${Endpoints.books}/$id'));
  
  static Uri getEmpruntsUri() => Uri.parse(getUrl(Endpoints.emprunts));
  static Uri getUserEmpruntsUri(String userId) => 
      Uri.parse(getUrl('${Endpoints.userEmprunts}/$userId'));
  
  static Uri getLateEmpruntsUri() => Uri.parse(getUrl(Endpoints.lateEmprunts));
  
  static Uri getReservationsUri() => Uri.parse(getUrl(Endpoints.reservations));
  static Uri getPendingReservationsUri() => 
      Uri.parse(getUrl(Endpoints.pendingReservations));
  
  static Uri getCategoriesUri() => Uri.parse(getUrl(Endpoints.categories));
  static Uri getRolesUri() => Uri.parse(getUrl(Endpoints.roles));
  
  static Uri getDashboardStatsUri() => Uri.parse(getUrl(Endpoints.dashboardStats));
  
  static Uri getTopBooksUri({int limit = 5}) {
    final uri = Uri.parse(getUrl(Endpoints.topBooks));
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'limit': limit.toString()
      }
    );
  }
  
  static Uri getRecentActivitiesUri({int limit = 10}) {
    final uri = Uri.parse(getUrl(Endpoints.recentActivities));
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'limit': limit.toString()
      }
    );
  }
  
  static Uri getCategoryStatsUri() => Uri.parse(getUrl(Endpoints.categoryStats));
  
  static Uri getSearchUri(String query) {
    final uri = Uri.parse(getUrl(Endpoints.search));
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'q': query
      }
    );
  }
  
  static Uri getLoginUri() => Uri.parse(getUrl(Endpoints.login));
  static Uri getLogoutUri() => Uri.parse(getUrl('logout'));
  static Uri getReturnBookUri() => Uri.parse(getUrl(Endpoints.returnBook));
  
  // Alternative: Méthode directe pour construire les URLs
  static Uri buildUri(String endpoint, {Map<String, String>? additionalParams}) {
    final Map<String, String> params = {
      'request': endpoint,
      if (additionalParams != null) ...additionalParams,
    };
    
    return Uri.parse('$baseUrl/index.php').replace(
      queryParameters: params,
    );
  }
  
  // URLs alternatives pour test
  static Uri getTestUsersUri() => buildUri('users');
  static Uri getTestLoginUri() => buildUri('login');
}

