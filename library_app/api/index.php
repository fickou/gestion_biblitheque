
<?php
// ============================================
// CONFIGURATION CORS COMPLÈTE - DOIT ÊTRE EN PREMIER
// ============================================

// Autoriser toutes les origines
header("Access-Control-Allow-Origin: *");

// Autoriser les méthodes HTTP
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH");

// Autoriser TOUS les headers, spécialement Authorization
header("Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With, Accept, Origin, Access-Control-Request-Method, Access-Control-Request-Headers");

// Autoriser les cookies si nécessaire
header("Access-Control-Allow-Credentials: true");

// Cache pour preflight
header("Access-Control-Max-Age: 3600");

// Toujours retourner du JSON
header("Content-Type: application/json; charset=UTF-8");

// GÉRER LES REQUÊTES OPTIONS IMMÉDIATEMENT
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    // Juste retourner les headers, pas de traitement
    http_response_code(200);
    exit(0);
}

// ============================================
// LOGGING POUR DÉBOGUER
// ============================================

// Activer l'affichage des erreurs pour débogage
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Logguer la requête
$log = "=== API REQUEST ===\n";
$log .= "Time: " . date('Y-m-d H:i:s') . "\n";
$log .= "Method: " . $_SERVER['REQUEST_METHOD'] . "\n";
$log .= "Request URI: " . $_SERVER['REQUEST_URI'] . "\n";
$log .= "Query String: " . ($_SERVER['QUERY_STRING'] ?? '') . "\n";

// Récupérer tous les headers
$headers = getallheaders();
$log .= "Headers:\n";
foreach ($headers as $key => $value) {
    $log .= "  $key: " . (strtolower($key) === 'authorization' ? substr($value, 0, 30) . '...' : $value) . "\n";
}

$log .= "===================\n";

// Écrire dans un fichier de log
file_put_contents('api_debug.log', $log, FILE_APPEND);

// ============================================
// INCLUDES
// ============================================

require_once '../config/database.php';
require_once 'models/User.php';
require_once 'models/Book.php';
require_once 'models/Emprunt.php';
require_once 'models/Reservation.php';
require_once 'models/Category.php';
require_once 'models/Role.php';
require_once 'controllers/DashboardController.php';

// ============================================
// FONCTIONS D'AUTH
// ============================================

function verifyToken() {
    $headers = getallheaders();
    $authHeader = $headers['Authorization'] ?? '';
    
    file_put_contents('api_debug.log', "Auth Header: $authHeader\n", FILE_APPEND);
    
    if (empty($authHeader)) {
        file_put_contents('api_debug.log', "No Authorization header\n", FILE_APPEND);
        return null;
    }
    
    // Supporter "Bearer token" ou juste "token"
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = $matches[1];
    } else {
        $token = $authHeader;
    }
    
    file_put_contents('api_debug.log', "Token extracted: " . substr($token, 0, 30) . "...\n", FILE_APPEND);
    
    try {
        // Décoder le token base64
        $decoded = base64_decode($token);
        
        if ($decoded === false) {
            file_put_contents('api_debug.log', "Failed to decode base64 token\n", FILE_APPEND);
            return null;
        }
        
        $parts = explode(':', $decoded);
        
        if (count($parts) >= 3) {
            $userId = $parts[0];
            $timestamp = $parts[1];
            $signature = $parts[2];
            
            file_put_contents('api_debug.log', "Token parts - UserID: $userId, Timestamp: $timestamp\n", FILE_APPEND);
            
            // Vérifier si le token a expiré (24 heures)
            $currentTime = time();
            if ($currentTime - $timestamp > 86400) {
                file_put_contents('api_debug.log', "Token expired: " . ($currentTime - $timestamp) . " seconds old\n", FILE_APPEND);
                return null;
            }
            
            // Vérifier la signature
            $expectedSignature = md5($userId . $timestamp . 'secret_key');
            
            if ($signature === $expectedSignature) {
                file_put_contents('api_debug.log', "Token VALID for user $userId\n", FILE_APPEND);
                return $userId;
            } else {
                file_put_contents('api_debug.log', "Invalid signature\n", FILE_APPEND);
            }
        } else {
            file_put_contents('api_debug.log', "Token doesn't have 3 parts\n", FILE_APPEND);
        }
    } catch (Exception $e) {
        file_put_contents('api_debug.log', "Token verification error: " . $e->getMessage() . "\n", FILE_APPEND);
    }
    
    return null;
}

function requireAuth() {
    $userId = verifyToken();
    
    if (!$userId) {
        http_response_code(401);
        echo json_encode([
            "success" => false, 
            "message" => "Non authentifié ou token invalide",
            "debug" => [
                "has_token" => !empty(getallheaders()['Authorization'] ?? ''),
                "user_id" => $userId
            ]
        ]);
        exit();
    }
    
    return $userId;
}

// ============================================
// ROUTER PRINCIPAL
// ============================================

try {
    // Initialiser la base de données
    $database = new Database();
    $db = $database->getConnection();
    
    // Récupérer la méthode HTTP
    $method = $_SERVER['REQUEST_METHOD'];
    $request = $_GET['request'] ?? '';
    $data = json_decode(file_get_contents("php://input"), true);
    
    file_put_contents('api_debug.log', "Routing: Method=$method, Request=$request\n", FILE_APPEND);
    
    // Routes qui ne nécessitent PAS d'authentification
    $publicRoutes = ['login', 'test', 'books', 'categories', 'search'];
    
    // Vérifier si la route est publique
    $routeIsPublic = false;
    foreach ($publicRoutes as $publicRoute) {
        if (strpos($request, $publicRoute) === 0) {
            $routeIsPublic = true;
            break;
        }
    }
    
    file_put_contents('api_debug.log', "Route is public: " . ($routeIsPublic ? 'YES' : 'NO') . "\n", FILE_APPEND);
    
    // Router
    switch($method) {
        case 'GET':
            if (!$routeIsPublic) {
                // Vérifier l'authentification pour les routes privées
                $currentUserId = requireAuth();
                file_put_contents('api_debug.log', "Authenticated user ID: $currentUserId\n", FILE_APPEND);
            }
            handleGetRequest($request, $db, $routeIsPublic ? null : $currentUserId);
            break;
            
        case 'POST':
            handlePostRequest($request, $db, $data);
            break;
            
        case 'PUT':
        case 'DELETE':
            // PUT et DELETE nécessitent toujours une auth
            $currentUserId = requireAuth();
            if ($method == 'PUT') {
                handlePutRequest($request, $db, $data, $currentUserId);
            } else {
                handleDeleteRequest($request, $db, $currentUserId);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(["success" => false, "message" => "Méthode non autorisée"]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Erreur serveur: " . $e->getMessage(),
        "trace" => $e->getTraceAsString()
    ]);
}

function handleGetRequest($request, $db) {
    $parts = explode('/', $request);
    
    switch($parts[0]) {
        case 'users':
            if(isset($parts[1])) {
                // GET /api/users/{id} - Nécessite auth
                $currentUserId = requireAuth();
                
                // Un utilisateur peut voir son propre profil, un admin peut voir tous
                $user = new User($db);
                $user->id = $parts[1];
                $user->readSingle();
                
                $currentUser = new User($db);
                $currentUser->id = $currentUserId;
                $currentUser->readSingle();
                
                // Vérifier les permissions
                if ($currentUserId != $parts[1] && $currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                echo json_encode([
                    "id" => $user->id,
                    "name" => $user->name,
                    "email" => $user->email,
                    "matricule" => $user->matricule,
                    "role" => [
                        "id" => $user->roleId,
                        "name" => $user->roleName,
                        "permissions" => $user->permissions
                    ],
                    "avatarText" => $user->avatarText,
                    "status" => $user->status,
                    "createdAt" => $user->createdAt,
                    "updatedAt" => $user->updatedAt
                ]);
            } else {
                // GET /api/users - Admin seulement
                requireAdmin($db);
                
                $user = new User($db);
                $stmt = $user->read();
                $users = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $users[] = $row;
                }
                
                echo json_encode($users);
            }
            break;
            
        case 'books':
            // Les livres sont accessibles à tous (avec ou sans auth)
            if(isset($parts[1])) {
                // GET /api/books/{id}
                $book = new Book($db);
                $book->id = $parts[1];
                $book->readSingle();
                
                echo json_encode([
                    "id" => $book->id,
                    "title" => $book->title,
                    "author" => $book->author,
                    "available" => $book->available,
                    "category" => [
                        "id" => $book->categoryId,
                        "name" => $book->categoryName
                    ],
                    "year" => $book->year,
                    "description" => $book->description,
                    "copies" => $book->copies,
                    "isbn" => $book->isbn,
                    "createdAt" => $book->createdAt,
                    "updatedAt" => $book->updatedAt
                ]);
            } else {
                // GET /api/books
                $book = new Book($db);
                $stmt = $book->read();
                $books = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $books[] = $row;
                }
                
                echo json_encode($books);
            }
            break;
            
        case 'emprunts':
            // TOUTES les routes emprunts nécessitent une authentification
            $currentUserId = requireAuth();
            $currentUser = new User($db);
            $currentUser->id = $currentUserId;
            $currentUser->readSingle();
            
            $emprunt = new Emprunt($db);
            
            if(isset($parts[1]) && $parts[1] == 'user' && isset($parts[2])) {
                // GET /api/emprunts/user/{userId}
                // Un utilisateur ne peut voir que ses propres emprunts
                // Un admin peut voir tous les emprunts
                if ($currentUserId != $parts[2] && $currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                $stmt = $emprunt->getByUser($parts[2]);
                $emprunts = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $emprunts[] = $row;
                }
                
                echo json_encode($emprunts);
            } else if(isset($parts[1]) && $parts[1] == 'late') {
                // GET /api/emprunts/late - Admin seulement
                if ($currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                $stmt = $emprunt->getLateLoans();
                $lateLoans = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $lateLoans[] = $row;
                }
                
                echo json_encode($lateLoans);
            } else {
                // GET /api/emprunts - Admin seulement
                if ($currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                $stmt = $emprunt->read();
                $emprunts = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $emprunts[] = $row;
                }
                
                echo json_encode($emprunts);
            }
            break;
            
        case 'reservations':
            // Nécessite auth
            $currentUserId = requireAuth();
            $currentUser = new User($db);
            $currentUser->id = $currentUserId;
            $currentUser->readSingle();
            
            $reservation = new Reservation($db);
            
            if(isset($parts[1]) && $parts[1] == 'pending') {
                // GET /api/reservations/pending - Admin seulement
                if ($currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                $stmt = $reservation->getPendingReservations();
                $reservations = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $reservations[] = $row;
                }
                
                echo json_encode($reservations);
            } else {
                // GET /api/reservations - Admin seulement
                if ($currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                    http_response_code(403);
                    echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                    return;
                }
                
                $stmt = $reservation->read();
                $reservations = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $reservations[] = $row;
                }
                
                echo json_encode($reservations);
            }
            break;
            
        case 'categories':
            // Accessible à tous
            $category = new Category($db);
            $stmt = $category->read();
            $categories = [];
            
            while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $categories[] = $row;
            }
            
            echo json_encode($categories);
            break;
            
        case 'roles':
            // Admin seulement
            requireAdmin($db);
            
            $role = new Role($db);
            $stmt = $role->read();
            $roles = [];
            
            while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $roles[] = $row;
            }
            
            echo json_encode($roles);
            break;
            
        case 'dashboard':
            // Nécessite auth
            $currentUserId = requireAuth();
            $currentUser = new User($db);
            $currentUser->id = $currentUserId;
            $currentUser->readSingle();
            
            $dashboard = new DashboardController($db);
            
            if(isset($parts[1])) {
                switch($parts[1]) {
                    case 'stats':
                        // Les stats dépendent du rôle
                        if ($currentUser->roleName === 'Admin' || $currentUser->roleName === 'Administrateur') {
                            echo json_encode($dashboard->getStats());
                        } else {
                            echo json_encode($dashboard->getUserStats($currentUserId));
                        }
                        break;
                    case 'top-books':
                        $limit = $_GET['limit'] ?? 5;
                        echo json_encode($dashboard->getTopBooks($limit));
                        break;
                    case 'recent-activities':
                        $limit = $_GET['limit'] ?? 10;
                        echo json_encode($dashboard->getRecentActivities($limit, $currentUserId));
                        break;
                    case 'category-stats':
                        if ($currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                            http_response_code(403);
                            echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                            return;
                        }
                        echo json_encode($dashboard->getCategoryStats());
                        break;
                }
            }
            break;
            
        case 'search':
            // Accessible à tous
            if(isset($_GET['q'])) {
                $book = new Book($db);
                $stmt = $book->search($_GET['q']);
                $results = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $results[] = $row;
                }
                
                echo json_encode($results);
            }
            break;
            
        case 'validate-token':
            // Endpoint pour valider le token
            $userId = verifyToken();
            if ($userId) {
                echo json_encode(["success" => true, "userId" => $userId]);
            } else {
                http_response_code(401);
                echo json_encode(["success" => false, "message" => "Token invalide"]);
            }
            break;
    }
}

function handlePostRequest($request, $db, $data) {
    switch($request) {
        case 'login':
            // Pas besoin d'auth pour le login
            $user = new User($db);
            if($user->login($data['email'], $data['password'])) {
                echo json_encode([
                    "success" => true,
                    "user" => [
                        "id" => $user->id,
                        "name" => $user->name,
                        "email" => $user->email,
                        "matricule" => $user->matricule,
                        "role" => [
                            "id" => $user->roleId,
                            "name" => $user->roleName,
                            "permissions" => $user->permissions
                        ],
                        "avatarText" => $user->avatarText,
                        "status" => $user->status
                    ],
                    "token" => generateToken($user->id)
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Identifiants incorrects"]);
            }
            break;
            
        case 'users':
            // Créer un utilisateur - Admin seulement
            requireAdmin($db);
            // ... reste du code existant
            break;
            
        case 'books':
            // Créer un livre - Admin seulement
            requireAdmin($db);
            // ... reste du code existant
            break;
            
        case 'emprunts':
            // Créer un emprunt - Nécessite auth
            $currentUserId = requireAuth();
            // ... reste du code existant
            break;
            
        case 'reservations':
            // Créer une réservation - Nécessite auth
            $currentUserId = requireAuth();
            // ... reste du code existant
            break;
            
        case 'return-book':
            // Retourner un livre - Nécessite auth (admin ou propriétaire)
            $currentUserId = requireAuth();
            $currentUser = new User($db);
            $currentUser->id = $currentUserId;
            $currentUser->readSingle();
            
            // Vérifier les permissions
            $emprunt = new Emprunt($db);
            $emprunt->id = $data['empruntId'];
            $emprunt->readSingle();
            
            if ($currentUserId != $emprunt->userId && $currentUser->roleName !== 'Admin' && $currentUser->roleName !== 'Administrateur') {
                http_response_code(403);
                echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
                return;
            }
            
            if($emprunt->returnBook()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
    }
}

function handleDeleteRequest($request, $db) {
    $parts = explode('/', $request);
    
    switch($parts[0]) {
        case 'users':
            $user = new User($db);
            $user->id = $parts[1];
            echo json_encode(["success" => $user->delete()]);
            break;
            
        case 'books':
            $book = new Book($db);
            $book->id = $parts[1];
            echo json_encode(["success" => $book->delete()]);
            break;
    }
}

function generateToken($userId) {
    return base64_encode($userId . ':' . time() . ':' . md5($userId . time() . 'secret_key'));
}