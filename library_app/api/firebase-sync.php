<?php
// firebase-sync.php - VERSION CORRIGÉE + SÉCURISÉE
ini_set('display_errors', 0);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/php_errors.log');

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$response = ["success" => false, "error" => "Erreur inconnue", "user" => null];

try {
    require_once __DIR__ . '/../config/database.php';
    require_once __DIR__ . '/models/User.php';

    $database = new Database();
    $db = $database->getConnection();

    if (!$db) throw new Exception("Connexion DB échouée");

    $user = new User($db);

    // ===== GET =====
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if (isset($_GET['uid'])) {
            $firebaseUid = $_GET['uid'];
            if ($user->findByFirebaseUid($firebaseUid)) {
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
                $response = [
                    "success" => false,
                    "error" => "Utilisateur non trouvé",
                    "user" => null
                ];
            }
        } else {
            $response["error"] = "Paramètre 'uid' manquant";
        }
    }

    // ===== POST =====
    elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $input = file_get_contents("php://input");
        $data = json_decode($input);

        if (!$data || json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception("JSON invalide");
        }

        if (empty($data->firebaseUid) || empty($data->email)) {
            throw new Exception("firebaseUid et email requis");
        }

        $userExists = $user->findByFirebaseUid($data->firebaseUid) || $user->findByEmail($data->email);

        if ($userExists) {
            $user->name = $data->name ?? $user->name;
            $user->email = $data->email;
            $user->matricule = $data->matricule ?? $user->matricule;
            if (!empty($data->role)) {
                $roleMap = ['Étudiant' => 3, 'Administrateur' => 1, 'Bibliothécaire' => 2];
                $user->roleId = $roleMap[$data->role] ?? 3;
                $user->roleName = $data->role;
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
                throw new Exception("Échec mise à jour utilisateur");
            }
        } else {
            // Création
            $user->firebaseUid = $data->firebaseUid;
            $user->name = $data->name ?? ($data->prenom . ' ' . $data->nom ?? '');
            $user->email = $data->email;
            $user->matricule = $data->matricule ?? '';
            $roleMap = ['Étudiant' => 3, 'Administrateur' => 1, 'Bibliothécaire' => 2];
            $user->roleId = $roleMap[$data->role] ?? 3;
            $user->roleName = $data->role ?? 'Étudiant';
            $user->status = 'actif';
            $nameParts = explode(' ', $user->name);
            $user->avatarText = count($nameParts) >= 2
                ? strtoupper(substr($nameParts[0],0,1).substr($nameParts[1],0,1))
                : strtoupper(substr($user->name,0,2));

            $userId = $user->create();
            if ($userId) {
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
                $response["error"] = "Échec de la création de l'utilisateur ou ID non récupéré";
                $response["user"] = null;
            }
        }
    } else {
        $response["error"] = "Méthode non supportée";
    }

} catch (Exception $e) {
    $response["error"] = $e->getMessage();
    $response["user"] = null;
    error_log("Exception globale: " . $e->getMessage());
}

http_response_code(200);
echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
exit();
