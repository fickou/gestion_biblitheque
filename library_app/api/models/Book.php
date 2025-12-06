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
        $query = "INSERT INTO " . $this->table . " 
                  SET id = :id, title = :title, author = :author, 
                      available = :available, categoryId = :categoryId,
                      year = :year, description = :description, 
                      copies = :copies, isbn = :isbn";
        
        $stmt = $this->conn->prepare($query);
        
        $this->id = uniqid();
        $this->available = $this->available ?? true;
        $this->copies = $this->copies ?? 1;
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':title', $this->title);
        $stmt->bindParam(':author', $this->author);
        $stmt->bindParam(':available', $this->available);
        $stmt->bindParam(':categoryId', $this->categoryId);
        $stmt->bindParam(':year', $this->year);
        $stmt->bindParam(':description', $this->description);
        $stmt->bindParam(':copies', $this->copies);
        $stmt->bindParam(':isbn', $this->isbn);
        
        if($stmt->execute()) {
            return $this->id;
        }
        
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table . " 
                  SET title = :title, author = :author, 
                      available = :available, categoryId = :categoryId,
                      year = :year, description = :description, 
                      copies = :copies, isbn = :isbn,
                      updatedAt = NOW()
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':title', $this->title);
        $stmt->bindParam(':author', $this->author);
        $stmt->bindParam(':available', $this->available);
        $stmt->bindParam(':categoryId', $this->categoryId);
        $stmt->bindParam(':year', $this->year);
        $stmt->bindParam(':description', $this->description);
        $stmt->bindParam(':copies', $this->copies);
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