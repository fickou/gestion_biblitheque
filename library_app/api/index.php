<?php
// api/index.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclure les fichiers nécessaires
require_once '../config/database.php';
require_once 'models/User.php';
require_once 'models/Book.php';
require_once 'models/Emprunt.php';
require_once 'models/Reservation.php';
require_once 'models/Category.php';
require_once 'models/Role.php';
require_once 'controllers/DashboardController.php';

// Initialiser la base de données
$database = new Database();
$db = $database->getConnection();

// Récupérer la méthode HTTP
$method = $_SERVER['REQUEST_METHOD'];
$request = $_GET['request'] ?? '';
$data = json_decode(file_get_contents("php://input"), true);

// Router
switch($method) {
    case 'GET':
        handleGetRequest($request, $db);
        break;
    case 'POST':
        handlePostRequest($request, $db, $data);
        break;
    case 'PUT':
        handlePutRequest($request, $db, $data);
        break;
    case 'DELETE':
        handleDeleteRequest($request, $db);
        break;
    default:
        http_response_code(405);
        echo json_encode(["message" => "Méthode non autorisée"]);
}

function handleGetRequest($request, $db) {
    $parts = explode('/', $request);
    
    switch($parts[0]) {
        case 'users':
            if(isset($parts[1])) {
                // GET /api/users/{id}
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
                // GET /api/users
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
                        echo json_encode($dashboard->getRecentActivities($limit));
                        break;
                    case 'category-stats':
                        echo json_encode($dashboard->getCategoryStats());
                        break;
                }
            }
            break;
            
        case 'search':
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
    }
}

function handlePostRequest($request, $db, $data) {
    switch($request) {
        case 'login':
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
            $user = new User($db);
            $user->name = $data['name'];
            $user->email = $data['email'];
            $user->matricule = $data['matricule'];
            $user->roleId = $data['roleId'];
            $user->avatarText = $data['avatarText'] ?? substr($data['name'], 0, 2);
            $user->status = $data['status'] ?? 'actif';
            
            if($user->create()) {
                echo json_encode(["success" => true, "id" => $user->id]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'books':
            $book = new Book($db);
            $book->title = $data['title'];
            $book->author = $data['author'];
            $book->categoryId = $data['categoryId'];
            $book->year = $data['year'];
            $book->description = $data['description'] ?? '';
            $book->copies = $data['copies'] ?? 1;
            $book->isbn = $data['isbn'] ?? '';
            
            if($book->create()) {
                echo json_encode(["success" => true, "id" => $book->id]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'emprunts':
            $emprunt = new Emprunt($db);
            $emprunt->bookId = $data['bookId'];
            $emprunt->userId = $data['userId'];
            $emprunt->borrowDate = date('Y-m-d');
            
            // Déterminer la date de retour selon le rôle
            $user = new User($db);
            $user->id = $data['userId'];
            $user->readSingle();
            
            $loanPeriod = ($user->roleName == 'Professeur') ? 60 : 30;
            $emprunt->returnDate = date('Y-m-d', strtotime("+{$loanPeriod} days"));
            
            if($emprunt->create()) {
                echo json_encode(["success" => true, "id" => $emprunt->id]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'reservations':
            $reservation = new Reservation($db);
            $reservation->bookId = $data['bookId'];
            $reservation->userId = $data['userId'];
            
            if($reservation->create()) {
                echo json_encode(["success" => true, "id" => $reservation->id]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
            
        case 'return-book':
            $emprunt = new Emprunt($db);
            $emprunt->id = $data['empruntId'];
            
            if($emprunt->returnBook()) {
                echo json_encode(["success" => true]);
            } else {
                echo json_encode(["success" => false]);
            }
            break;
    }
}

function handlePutRequest($request, $db, $data) {
    $parts = explode('/', $request);
    
    switch($parts[0]) {
        case 'users':
            $user = new User($db);
            $user->id = $parts[1];
            $user->name = $data['name'];
            $user->email = $data['email'];
            $user->matricule = $data['matricule'];
            $user->roleId = $data['roleId'];
            $user->avatarText = $data['avatarText'];
            $user->status = $data['status'];
            
            echo json_encode(["success" => $user->update()]);
            break;
            
        case 'books':
            $book = new Book($db);
            $book->id = $parts[1];
            $book->title = $data['title'];
            $book->author = $data['author'];
            $book->categoryId = $data['categoryId'];
            $book->year = $data['year'];
            $book->description = $data['description'];
            $book->copies = $data['copies'];
            $book->isbn = $data['isbn'];
            $book->available = $data['available'];
            
            echo json_encode(["success" => $book->update()]);
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