<?php
// api/models/Role.php
class Role {
    private $conn;
    private $table = 'Roles';

    public $id;
    public $name;
    public $permissions;
    public $createdAt;
    public $updatedAt;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT * FROM " . $this->table . " ORDER BY name";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }
}