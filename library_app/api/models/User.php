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
            $query = "INSERT INTO " . $this->table . " 
                    SET id = :id, name = :name, email = :email, 
                        matricule = :matricule, roleId = :roleId,
                        avatarText = :avatarText, status = :status";
            
            $stmt = $this->conn->prepare($query);
            
            $this->id = uniqid();
            $this->status = $this->status ?? 'actif';
            
            $stmt->bindParam(':id', $this->id);
            $stmt->bindParam(':name', $this->name);
            $stmt->bindParam(':email', $this->email);
            $stmt->bindParam(':matricule', $this->matricule);
            $stmt->bindParam(':roleId', $this->roleId);
            $stmt->bindParam(':avatarText', $this->avatarText);
            $stmt->bindParam(':status', $this->status);
            
            if($stmt->execute()) {
                return $this->id;
            }
            
            return false;
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
    }