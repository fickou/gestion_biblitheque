<?php
// api/models/Category.php
class Category {
    private $conn;
    private $table = 'Categories';

    public $id;
    public $name;
    public $description;
    public $createdAt;
    public $updatedAt;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT c.*, 
                  (SELECT COUNT(*) FROM Books WHERE categoryId = c.id) as bookCount
                  FROM " . $this->table . " c
                  ORDER BY c.name";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table . " 
                  SET id = :id, name = :name, description = :description";
        
        $stmt = $this->conn->prepare($query);
        
        $this->id = uniqid();
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':name', $this->name);
        $stmt->bindParam(':description', $this->description);
        
        return $stmt->execute();
    }
}