<?php
// firebase-sync.php - VERSION CORRIGÉE
// Activer les logs
ini_set('display_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php_errors.log');

// DÉFINIR LES HEADERS EN PREMIER - IMPORTANT POUR CORS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Gérer les requêtes OPTIONS (CORS preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$response = ["success" => false, "error" => "Erreur inconnue"];

try {
    // Log de début
    error_log("=== FIREBASE-SYNC.PHP Appelé ===");
    error_log("Méthode: " . $_SERVER['REQUEST_METHOD']);
    error_log("URI: " . $_SERVER['REQUEST_URI']);
    
    // Chemin des fichiers
    $configFile = __DIR__ . '/../config/database.php';
    $modelFile = __DIR__ . '/models/User.php';
    
    if (!file_exists($configFile)) {
        throw new Exception("Fichier config introuvable: $configFile");
    }
    
    if (!file_exists($modelFile)) {
        throw new Exception("Fichier modèle introuvable: $modelFile");
    }
    
    require_once $configFile;
    require_once $modelFile;
    
    // Initialiser
    $database = new Database();
    $db = $database->getConnection();
    
    if (!$db) {
        throw new Exception("Connexion DB échouée: " . print_r($database->getError(), true));
    }
    
    $user = new User($db);
    
    // ========== GESTION DES REQUÊTES GET ==========
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if (isset($_GET['uid'])) {
            $firebaseUid = $_GET['uid'];
            error_log("GET - Recherche UID: $firebaseUid");
            
            if ($user->findByFirebaseUid($firebaseUid)) {
                error_log("✅ Utilisateur trouvé: " . $user->email);
                $response = [
                    "success" => true,
                    "user" => [
                        "id" => (int)$user->id,
                        "firebaseUid" => $user->firebaseUid,
                        "name" => $user->name,
                        "email" => $user->email,
                        "matricule" => $user->matricule,
                        "role" => $user->roleName,
                        "avatarText" => $user->avatarText
                    ]
                ];
            } else {
                error_log("❌ Utilisateur non trouvé avec UID: $firebaseUid");
                $response = [
                    "success" => false,
                    "error" => "Utilisateur non trouvé"
                ];
            }
        } else {
            $response = [
                "success" => false,
                "error" => "Paramètre 'uid' manquant dans la requête GET"
            ];
        }
    }
    
    // ========== GESTION DES REQUÊTES POST ==========
    elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = file_get_contents("php://input");
        error_log("Données POST reçues: " . $input);
        
        if (empty($input)) {
            throw new Exception("Aucune donnée reçue dans la requête POST");
        }
        
        $data = json_decode($input);
        
        if (!$data || json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("JSON invalide: " . json_last_error_msg());
        }
        
        if (empty($data->firebaseUid) || empty($data->email)) {
            throw new Exception("Données manquantes: firebaseUid et email requis");
        }
        
        error_log("Vérification si utilisateur existe...");
        $userExists = false;
        
        // Vérifier par Firebase UID
        if ($user->findByFirebaseUid($data->firebaseUid)) {
            error_log("✅ Utilisateur trouvé par Firebase UID: " . $data->firebaseUid);
            $userExists = true;
        } 
        // Sinon vérifier par email
        elseif ($user->findByEmail($data->email)) {
            error_log("✅ Utilisateur trouvé par email: " . $data->email);
            $userExists = true;
        } else {
            error_log("❌ Utilisateur non trouvé - création nécessaire");
        }
        
        if ($userExists) {
            // MISE À JOUR
            error_log("Mise à jour de l'utilisateur existant...");
            $user->name = $data->name ?? $user->name;
            $user->email = $data->email;
            $user->matricule = $data->matricule ?? $user->matricule;
            
            if (!empty($data->role)) {
                $roleMap = ['Étudiant' => 3, 'Administrateur' => 1, 'Bibliothécaire' => 2];
                $user->roleId = $roleMap[$data->role] ?? 3;
                $user->roleName = $data->role;
            }
            
            if (empty($user->firebaseUid)) {
                $user->firebaseUid = $data->firebaseUid;
            }
            
            if ($user->update()) {
                $response = [
                    "success" => true,
                    "message" => "Utilisateur mis à jour",
                    "userId" => (int)$user->id,
                    "user" => [
                        "id" => (int)$user->id,
                        "firebaseUid" => $user->firebaseUid,
                        "name" => $user->name,
                        "email" => $user->email,
                        "matricule" => $user->matricule,
                        "role" => $user->roleName,
                        "avatarText" => $user->avatarText
                    ]
                ];
            } else {
                throw new Exception("Échec de la mise à jour de l'utilisateur");
            }
        } else {
            // CRÉATION
            error_log("Création d'un nouvel utilisateur...");
            $user->firebaseUid = $data->firebaseUid;
            $user->name = $data->name ?? ($data->prenom . ' ' . $data->nom);
            $user->email = $data->email;
            $user->matricule = $data->matricule ?? '';
            
            $roleMap = ['Étudiant' => 3, 'Administrateur' => 1, 'Bibliothécaire' => 2];
            $user->roleId = $roleMap[$data->role] ?? 3;
            $user->roleName = $data->role ?? 'Étudiant';
            $user->status = 'actif';
            
            // Générer avatar
            $nameParts = explode(' ', $user->name);
            $user->avatarText = count($nameParts) >= 2 
                ? strtoupper(substr($nameParts[0], 0, 1) . substr($nameParts[1], 0, 1))
                : strtoupper(substr($user->name, 0, 2));
            
            error_log("Appel de user->create()...");
            $userId = $user->create();
            
            if ($userId) {
                error_log("✅ Création réussie, ID: $userId");
                
                $response = [
                    "success" => true,
                    "message" => "Nouvel utilisateur créé",
                    "userId" => (int)$userId,
                    "user" => [
                        "id" => (int)$userId,
                        "firebaseUid" => $user->firebaseUid,
                        "name" => $user->name,
                        "email" => $user->email,
                        "matricule" => $user->matricule,
                        "role" => $user->roleName,
                        "avatarText" => $user->avatarText
                    ]
                ];
            } else {
                error_log("❌ Échec de la création");
                throw new Exception("Échec de la création de l'utilisateur");
            }
        }
    }
    
    else {
        $response = [
            "success" => false,
            "error" => "Méthode non supportée: " . $_SERVER['REQUEST_METHOD']
        ];
    }
    
} catch (Exception $e) {
    error_log("❌ Exception globale: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    $response = [
        "success" => false,
        "error" => $e->getMessage()
    ];
}

// Toujours retourner JSON
http_response_code(200);
echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
error_log("Réponse envoyée: " . json_encode($response));
exit();