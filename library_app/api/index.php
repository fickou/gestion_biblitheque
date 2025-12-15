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
    $log .= "  $key: " . $value . "\n";
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
// FONCTIONS D'AUTH SANS TOKENS
// ============================================

function checkBasicAuth() {
    // Méthode basique sans tokens - à remplacer par votre propre système d'auth
    $headers = getallheaders();
    
    // Vérifier si un header Authorization existe (pour compatibilité)
    $authHeader = $headers['Authorization'] ?? '';
    
    if (empty($authHeader)) {
        file_put_contents('api_debug.log', "No Authorization header\n", FILE_APPEND);
        return null;
    }
    
    // Pour l'instant, retourner null car les tokens sont désactivés
    file_put_contents('api_debug.log', "Tokens are disabled - using no authentication\n", FILE_APPEND);
    return null;
}

function requireAuth() {
    // Sans tokens, on ne peut pas authentifier
    http_response_code(401);
    echo json_encode([
        "success" => false, 
        "message" => "Authentification désactivée (tokens supprimés)",
        "debug" => [
            "auth_system" => "disabled"
        ]
    ]);
    exit();
}

function requireAdmin($db) {
    // Sans authentification, impossible de vérifier les rôles admin
    requireAuth();
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
    // TOUTES les routes sont maintenant publiques car les tokens sont désactivés
    $publicRoutes = ['login', 'test', 'books', 'categories', 'search', 'users', 'emprunts', 'reservations', 'roles', 'dashboard', 'validate-token'];
    
    // Vérifier si la route est publique (toutes le sont maintenant)
    $routeIsPublic = true; // Toutes les routes sont publiques sans tokens
    
    file_put_contents('api_debug.log', "Route is public: YES (tokens disabled)\n", FILE_APPEND);
    
    // Router
    switch($method) {
        case 'GET':
            // Toutes les routes GET sont accessibles sans auth
            handleGetRequest($request, $db, null);
            break;
            
        case 'POST':
            // Toutes les routes POST sont accessibles sans auth
            handlePostRequest($request, $db, $data);
            break;
            
        case 'PUT':
        case 'DELETE':
            // Toutes les routes PUT/DELETE sont accessibles sans auth
            if ($method == 'PUT') {
                handlePutRequest($request, $db, $data, null);
            } else {
                handleDeleteRequest($request, $db, null);
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
                // GET /api/users/{id} - Accessible à tous (tokens désactivés)
                $user = new User($db);
                $user->id = $parts[1];
                $user->readSingle();
                
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
               // GET /api/users - Accessible selon le rôle
                $user = new User($db);
                $stmt = $user->readByRole('Etudiant');
                $users = [];

                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $users[] = $row;
                }

                echo json_encode($users);
            }
            break;
            
        case 'books':
            // Les livres sont accessibles à tous
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
            // Toutes les routes emprunts sont accessibles sans auth
            $emprunt = new Emprunt($db);
            
            if(isset($parts[1]) && $parts[1] == 'user' && isset($parts[2])) {
                // GET /api/emprunts/user/{userId}
                $stmt = $emprunt->getByUser($parts[2]);
                $emprunts = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $emprunts[] = $row;
                }
                
                echo json_encode($emprunts);
            } else if(isset($parts[1]) && $parts[1] == 'late') {
                // GET /api/emprunts/late
                $stmt = $emprunt->getLateLoans();
                $lateLoans = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $lateLoans[] = $row;
                }
                
                echo json_encode($lateLoans);
            } else {
                // GET /api/emprunts
                $stmt = $emprunt->read();
                $emprunts = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $emprunts[] = $row;
                }
                
                echo json_encode($emprunts);
            }
            break;
            
        case 'reservations':
            $reservation = new Reservation($db);
            
            if(isset($parts[1]) && $parts[1] == 'pending') {
                // GET /api/reservations/pending
                $stmt = $reservation->getPendingReservations();
                $reservations = [];
                
                while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                    $reservations[] = $row;
                }
                
                echo json_encode($reservations);
            } else {
                // GET /api/reservations
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
            $role = new Role($db);
            $stmt = $role->read();
            $roles = [];
            
            while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $roles[] = $row;
            }
            
            echo json_encode($roles);
            break;
            
        case 'dashboard':
            $dashboard = new DashboardController($db);
            
            if(isset($parts[1])) {
                switch($parts[1]) {
                    case 'stats':
                        echo json_encode($dashboard->getStats());
                        break;
                    case 'top-books':
                        $limit = $_GET['limit'] ?? 5;
                        echo json_encode($dashboard->getTopBooks($limit));
                        break;
                    case 'recent-activities':
                        $limit = $_GET['limit'] ?? 10;
                        echo json_encode($dashboard->getRecentActivities($limit, null));
                        break;
                    case 'category-stats':
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
            // Endpoint inutile sans tokens
            echo json_encode([
                "success" => false, 
                "message" => "Tokens désactivés",
                "auth_system" => "disabled"
            ]);
            break;
    }
}

function handlePostRequest($request, $db, $data) {
    switch($request) {
        case 'login':
            // Fonctionnalité de login toujours disponible
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
                    "message" => "Login réussi (tokens désactivés)"
                ]);
            } else {
                echo json_encode(["success" => false, "message" => "Identifiants incorrects"]);
            }
            break;
            
        case 'users':
            // Créer un utilisateur - Accessible à tous (tokens désactivés)
            $user = new User($db);
            $user->name = $data['name'] ?? '';
            $user->email = $data['email'] ?? '';
            $user->password = $data['password'] ?? '';
            $user->matricule = $data['matricule'] ?? '';
            $user->roleId = $data['roleId'] ?? 2;
            
            if ($user->create()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'books':
            // Créer un livre - Accessible à tous (tokens désactivés)
            $book = new Book($db);
            $book->title = $data['title'] ?? '';
            $book->author = $data['author'] ?? '';
            $book->categoryId = $data['categoryId'] ?? 1;
            $book->year = $data['year'] ?? date('Y');
            $book->description = $data['description'] ?? '';
            $book->copies = $data['copies'] ?? 1;
            $book->isbn = $data['isbn'] ?? '';
            
            if ($book->create()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'emprunts':
            // Créer un emprunt - Accessible à tous (tokens désactivés)
            $emprunt = new Emprunt($db);
            $emprunt->userId = $data['userId'] ?? null;
            $emprunt->bookId = $data['bookId'] ?? null;
            $emprunt->dateEmprunt = date('Y-m-d H:i:s');
            $emprunt->dateRetourPrevue = $data['dateRetourPrevue'] ?? date('Y-m-d H:i:s', strtotime('+14 days'));
            
            if ($emprunt->create()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'reservations':
            // Créer une réservation - Accessible à tous (tokens désactivés)
            $reservation = new Reservation($db);
            $reservation->userId = $data['userId'] ?? null;
            $reservation->bookId = $data['bookId'] ?? null;
            $reservation->dateReservation = date('Y-m-d H:i:s');
            $reservation->status = 'pending';
            
            if ($reservation->create()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'return-book':
            // Retourner un livre - Accessible à tous (tokens désactivés)
            $emprunt = new Emprunt($db);
            $emprunt->id = $data['empruntId'];
            $emprunt->readSingle();
            
            if($emprunt->returnBook()) {
                echo json_encode(["success" => true, "message" => "Livre retourné avec succès"]);
            } else {
                echo json_encode(["success" => false, "message" => "Erreur lors du retour"]);
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

function handlePutRequest($request, $db, $data) {
    $parts = explode('/', $request);
    
    switch($parts[0]) {
        case 'users':
            $user = new User($db);
            $user->id = $parts[1];
            $user->name = $data['name'] ?? '';
            $user->email = $data['email'] ?? '';
            $user->matricule = $data['matricule'] ?? '';
            $user->roleId = $data['roleId'] ?? 2;
            
            if ($user->update()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'books':
            $book = new Book($db);
            $book->id = $parts[1];
            $book->title = $data['title'] ?? '';
            $book->author = $data['author'] ?? '';
            $book->categoryId = $data['categoryId'] ?? 1;
            $book->year = $data['year'] ?? date('Y');
            $book->description = $data['description'] ?? '';
            $book->copies = $data['copies'] ?? 1;
            $book->isbn = $data['isbn'] ?? '';
            $book->available = $data['available'] ?? 1;
            
            if ($book->update()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
    }
}