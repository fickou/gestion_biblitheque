    <?php
    // api/models/User.php
    class User {
        private $conn;
        private $table = 'Users';

        public $id;
        public $name;
        public $email;
        public $matricule;
        public $roleId;
        public $avatarText;
        public $status;
        public $createdAt;
        public $updatedAt;

  
        public $roleName;     // Déclarez cette propriété
        public $permissions;  // Déclarez cette propriété

        public function __construct($db) {
            $this->conn = $db;
        }

        public function read() {
            $query = "SELECT u.*, r.name as roleName, r.permissions 
                    FROM " . $this->table . " u
                    LEFT JOIN Roles r ON u.roleId = r.id
                    ORDER BY u.createdAt DESC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->execute();
            
            return $stmt;
        }

        public function readSingle() {
            $query = "SELECT u.*, r.name as roleName, r.permissions 
                    FROM " . $this->table . " u
                    LEFT JOIN Roles r ON u.roleId = r.id
                    WHERE u.id = ? LIMIT 0,1";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(1, $this->id);
            $stmt->execute();
            
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if($row) {
                $this->name = $row['name'];
                $this->email = $row['email'];
                $this->matricule = $row['matricule'];
                $this->roleId = $row['roleId'];
                $this->roleName = $row['roleName'];
                $this->permissions = json_decode($row['permissions'], true);
                $this->avatarText = $row['avatarText'];
                $this->status = $row['status'];
                $this->createdAt = $row['createdAt'];
                $this->updatedAt = $row['updatedAt'];
            }
        }

        public function create() {
            try {
                error_log("=== DEBUG CREATE USER ===");
                error_log("Données à insérer:");
                error_log("firebase_uid: " . $this->firebaseUid);
                error_log("email: " . $this->email);
                error_log("name: " . $this->name);
                error_log("matricule: " . $this->matricule);
                error_log("roleId: " . $this->roleId . " (type: " . gettype($this->roleId) . ")");
                error_log("status: " . $this->status);
                error_log("avatarText: " . $this->avatarText);
                
                $query = "INSERT INTO users 
                        (firebase_uid, email, name, matricule, roleId, status, avatarText, createdAt, updatedAt)
                        VALUES 
                        (:firebase_uid, :email, :name, :matricule, :roleId, :status, :avatarText, NOW(), NOW())";
                
                $stmt = $this->conn->prepare($query);
                
                // Convertir l'ID de rôle en INT
                $roleIdInt = (int)$this->roleId;
                error_log("roleId converti: " . $roleIdInt);
                
                $stmt->bindParam(":firebase_uid", $this->firebaseUid);
                $stmt->bindParam(":email", $this->email);
                $stmt->bindParam(":name", $this->name);
                $stmt->bindParam(":matricule", $this->matricule);
                $stmt->bindParam(":roleId", $roleIdInt, PDO::PARAM_INT);
                $stmt->bindParam(":status", $this->status);
                $stmt->bindParam(":avatarText", $this->avatarText);
                
                error_log("Exécution de la requête...");
                $result = $stmt->execute();
                
                if ($result) {
                    $lastId = $this->conn->lastInsertId();
                    error_log("✅ INSERT réussi! ID: " . $lastId);
                    return (int)$lastId;
                } else {
                    // Récupérer l'erreur PDO
                    $errorInfo = $stmt->errorInfo();
                    error_log("❌ Erreur SQL: " . print_r($errorInfo, true));
                    return false;
                }
                
            } catch (Exception $e) {
                error_log("❌ Exception dans create(): " . $e->getMessage());
                error_log("File: " . $e->getFile() . " Line: " . $e->getLine());
                return false;
            }
        }

        public function update() {
            $query = "UPDATE " . $this->table . " 
                    SET name = :name, email = :email, 
                        matricule = :matricule, roleId = :roleId,
                        avatarText = :avatarText, status = :status
                    WHERE id = :id";
            
            $stmt = $this->conn->prepare($query);
            
            $stmt->bindParam(':id', $this->id);
            $stmt->bindParam(':name', $this->name);
            $stmt->bindParam(':email', $this->email);
            $stmt->bindParam(':matricule', $this->matricule);
            $stmt->bindParam(':roleId', $this->roleId);
            $stmt->bindParam(':avatarText', $this->avatarText);
            $stmt->bindParam(':status', $this->status);
            
            return $stmt->execute();
        }

        public function delete() {
            $query = "DELETE FROM " . $this->table . " WHERE id = :id";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':id', $this->id);
            
            return $stmt->execute();
        }

        public function login($email, $password) {
            $query = "SELECT u.*, r.name as roleName, r.permissions 
                    FROM " . $this->table . " u
                    LEFT JOIN Roles r ON u.roleId = r.id
                    WHERE u.email = :email AND u.status = 'actif'";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':email', $email);
            $stmt->execute();
            
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if($row) {
                $this->id = $row['id'];
                $this->name = $row['name'];
                $this->email = $row['email'];
                $this->matricule = $row['matricule'];
                $this->roleId = $row['roleId'];
                $this->roleName = $row['roleName'];
                $this->permissions = json_decode($row['permissions'], true);
                $this->avatarText = $row['avatarText'];
                $this->status = $row['status'];
                
                return true;
            }
            
            return false;
        }

        public function findByFirebaseUid($firebaseUid) {
            try {
                $query = "SELECT u.*, r.name as role_name, r.permissions 
                        FROM users u 
                        LEFT JOIN roles r ON u.roleId = r.id 
                        WHERE u.firebase_uid = :firebase_uid 
                        LIMIT 1";
                
                $stmt = $this->conn->prepare($query);
                $stmt->bindParam(":firebase_uid", $firebaseUid);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    $row = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    // Hydrater l'objet
                    $this->id = $row['id'];
                    $this->firebaseUid = $row['firebase_uid'];
                    $this->name = $row['name'];
                    $this->email = $row['email'];
                    $this->matricule = $row['matricule'];
                    $this->roleId = $row['roleId'];
                    $this->roleName = $row['role_name'];
                    $this->permissions = $row['permissions'] ? json_decode($row['permissions'], true) : [];
                    $this->avatarText = $row['avatarText'] ?? '';
                    $this->status = $row['status'] ?? 'actif';
                    $this->createdAt = $row['createdAt'];
                    $this->updatedAt = $row['updatedAt'];
                    
                    return true;
                }
                
                return false;
            } catch (Exception $e) {
                error_log("Erreur findByFirebaseUid: " . $e->getMessage());
                return false;
            }
        }

        public function findByEmail($email) {
            try {
                $query = "SELECT u.*, r.name as role_name, r.permissions 
                        FROM users u 
                        LEFT JOIN roles r ON u.roleId = r.id 
                        WHERE u.email = :email 
                        LIMIT 1";
                
                $stmt = $this->conn->prepare($query);
                $stmt->bindParam(":email", $email);
                $stmt->execute();
                
                if ($stmt->rowCount() > 0) {
                    $row = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    // Hydrater l'objet
                    $this->id = $row['id'];
                    $this->firebaseUid = $row['firebase_uid'];
                    $this->name = $row['name'];
                    $this->email = $row['email'];
                    $this->matricule = $row['matricule'];
                    $this->roleId = $row['roleId'];
                    $this->roleName = $row['role_name'];
                    $this->permissions = $row['permissions'] ? json_decode($row['permissions'], true) : [];
                    $this->avatarText = $row['avatarText'] ?? '';
                    $this->status = $row['status'] ?? 'actif';
                    $this->createdAt = $row['createdAt'];
                    $this->updatedAt = $row['updatedAt'];
                    
                    return true;
                }
                
                return false;
            } catch (Exception $e) {
                error_log("Erreur findByEmail: " . $e->getMessage());
                return false;
            }
        }

        public function readByRole($roleName) {
            $query = "SELECT u.*, r.name as roleName, r.permissions 
                    FROM users u 
                    LEFT JOIN roles r ON u.roleId = r.id 
                    WHERE r.name = :roleName
                    ORDER BY u.name ASC";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':roleName', $roleName);
            $stmt->execute();
            
            return $stmt;
        }
    }