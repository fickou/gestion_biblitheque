<?php
// api/models/Book.php
class Book {
    private $conn;
    private $table = 'Books';

    public $id;
    public $title;
    public $author;
    public $available;
    public $categoryId;
    public $year;
    public $description;
    public $copies;
    public $isbn;
    public $createdAt;
    public $updatedAt;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT b.*, c.name as categoryName 
                  FROM " . $this->table . " b
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  ORDER BY b.createdAt DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function readSingle() {
        $query = "SELECT b.*, c.name as categoryName 
                  FROM " . $this->table . " b
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  WHERE b.id = ? LIMIT 0,1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();
        
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if($row) {
            $this->title = $row['title'];
            $this->author = $row['author'];
            $this->available = $row['available'];
            $this->categoryId = $row['categoryId'];
            $this->categoryName = $row['categoryName'];
            $this->year = $row['year'];
            $this->description = $row['description'];
            $this->copies = $row['copies'];
            $this->isbn = $row['isbn'];
            $this->createdAt = $row['createdAt'];
            $this->updatedAt = $row['updatedAt'];
        }
    }

   public function create() {
    // 1. VÉRIFIER/CREER LA CATÉGORIE D'ABORD
    $categoryId = $this->createOrGetCategory($this->categoryId);
    
    if (!$categoryId) {
        // Si on ne peut pas créer/récupérer la catégorie
        return false;
    }
    
    // 2. MAINTENANT CRÉER LE LIVRE
    $query = "INSERT INTO " . $this->table . " 
              SET id = :id, title = :title, author = :author, 
                  available = :available, categoryId = :categoryId,
                  year = :year, description = :description, 
                  copies = :copies, isbn = :isbn,
                  createdAt = NOW(), updatedAt = NOW()";
    
    $stmt = $this->conn->prepare($query);
    
    // Générer ID unique
    $this->id = uniqid();
    
    // CORRECTION CRITIQUE: Convertir available en int (1/0)
    $availableInt = $this->available ? 1 : 0;
    
    // CORRECTION: Utiliser l'ID de catégorie validé/créé
    $this->categoryId = $categoryId;
    
    $stmt->bindParam(':id', $this->id);
    $stmt->bindParam(':title', $this->title);
    $stmt->bindParam(':author', $this->author);
    $stmt->bindParam(':available', $availableInt, PDO::PARAM_INT); // <-- IMPORTANT
    $stmt->bindParam(':categoryId', $this->categoryId);
    $stmt->bindParam(':year', $this->year);
    $stmt->bindParam(':description', $this->description);
    $stmt->bindParam(':copies', $this->copies, PDO::PARAM_INT);
    $stmt->bindParam(':isbn', $this->isbn);
    
    if($stmt->execute()) {
        return $this->id;
    }
    
    return false;
}

// NOUVELLE MÉTHODE POUR GÉRER LES CATÉGORIES
private function createOrGetCategory($categoryName) {
    // Générer un ID propre à partir du nom
    $categoryId = strtolower(preg_replace('/[^a-zA-Z0-9]+/', '-', trim($categoryName)));
    
    // Vérifier si la catégorie existe déjà
    $checkQuery = "SELECT id FROM Categories WHERE id = :id OR name = :name";
    $checkStmt = $this->conn->prepare($checkQuery);
    $checkStmt->bindParam(':id', $categoryId);
    $checkStmt->bindParam(':name', $categoryName);
    $checkStmt->execute();
    
    $existingCategory = $checkStmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existingCategory) {
        // La catégorie existe, retourner son ID
        return $existingCategory['id'];
    }
    
    // Créer la nouvelle catégorie
    $createQuery = "INSERT INTO Categories (id, name, description) 
                    VALUES (:id, :name, :description)";
    $createStmt = $this->conn->prepare($createQuery);
    
    $description = "Catégorie créée automatiquement: " . $categoryName;
    
    $createStmt->bindParam(':id', $categoryId);
    $createStmt->bindParam(':name', $categoryName);
    $createStmt->bindParam(':description', $description);
    
    if ($createStmt->execute()) {
        return $categoryId;
    }
    
    return false;
}

   public function update() {
    // 1. VÉRIFIER/CREER LA CATÉGORIE SI NÉCESSAIRE
    $categoryId = $this->createOrGetCategory($this->categoryId);
    
    if (!$categoryId) {
        return false;
    }
    
    $query = "UPDATE " . $this->table . " 
              SET title = :title, author = :author, 
                  available = :available, categoryId = :categoryId,
                  year = :year, description = :description, 
                  copies = :copies, isbn = :isbn,
                  updatedAt = NOW()
              WHERE id = :id";
    
    $stmt = $this->conn->prepare($query);
    
    // CORRECTION: Convertir available en int
    $availableInt = $this->available ? 1 : 0;
    $this->categoryId = $categoryId;
    
    $stmt->bindParam(':id', $this->id);
    $stmt->bindParam(':title', $this->title);
    $stmt->bindParam(':author', $this->author);
    $stmt->bindParam(':available', $availableInt, PDO::PARAM_INT);
    $stmt->bindParam(':categoryId', $this->categoryId);
    $stmt->bindParam(':year', $this->year);
    $stmt->bindParam(':description', $this->description);
    $stmt->bindParam(':copies', $this->copies, PDO::PARAM_INT);
    $stmt->bindParam(':isbn', $this->isbn);
    
    return $stmt->execute();
}
    
    public function delete() {
        $query = "DELETE FROM " . $this->table . " WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $this->id);
        
        return $stmt->execute();
    }

    public function search($keywords) {
        $query = "SELECT b.*, c.name as categoryName 
                  FROM " . $this->table . " b
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  WHERE b.title LIKE ? OR b.author LIKE ? 
                  OR c.name LIKE ? OR b.isbn LIKE ?
                  ORDER BY b.title";
        
        $keywords = "%{$keywords}%";
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(1, $keywords);
        $stmt->bindParam(2, $keywords);
        $stmt->bindParam(3, $keywords);
        $stmt->bindParam(4, $keywords);
        
        $stmt->execute();
        
        return $stmt;
    }

    public function getAvailableBooks() {
        $query = "SELECT b.*, c.name as categoryName 
                  FROM " . $this->table . " b
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  WHERE b.available = 1 AND b.copies > 0
                  ORDER BY b.title";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function updateCopies($increment = true) {
        $operation = $increment ? 'copies + 1' : 'copies - 1';
        $query = "UPDATE " . $this->table . " 
                  SET copies = " . $operation . ",
                      available = CASE 
                          WHEN " . $operation . " > 0 THEN 1 
                          ELSE 0 
                      END
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $this->id);
        
        return $stmt->execute();
    }
}
?>