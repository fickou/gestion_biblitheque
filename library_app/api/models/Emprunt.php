<?php
// api/models/Emprunt.php
class Emprunt {
    private $conn;
    private $table = 'Emprunts';

    public $id;
    public $bookId;
    public $userId;
    public $borrowDate;
    public $returnDate;
    public $status;
    public $createdAt;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT e.*, b.title as bookTitle, b.author as bookAuthor,
                         u.name as userName, u.matricule as userMatricule
                  FROM " . $this->table . " e
                  LEFT JOIN Books b ON e.bookId = b.id
                  LEFT JOIN Users u ON e.userId = u.id
                  ORDER BY e.createdAt DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function readSingle() {
        $query = "SELECT e.*, b.title as bookTitle, b.author as bookAuthor,
                         u.name as userName, u.matricule as userMatricule
                  FROM " . $this->table . " e
                  LEFT JOIN Books b ON e.bookId = b.id
                  LEFT JOIN Users u ON e.userId = u.id
                  WHERE e.id = ? LIMIT 0,1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->id);
        $stmt->execute();
        
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function create() {
        $query = "INSERT INTO " . $this->table . " 
                  SET id = :id, bookId = :bookId, userId = :userId,
                      borrowDate = :borrowDate, returnDate = :returnDate,
                      status = :status";
        
        $stmt = $this->conn->prepare($query);
        
        $this->id = uniqid();
        $this->status = $this->status ?? 'En cours';
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':bookId', $this->bookId);
        $stmt->bindParam(':userId', $this->userId);
        $stmt->bindParam(':borrowDate', $this->borrowDate);
        $stmt->bindParam(':returnDate', $this->returnDate);
        $stmt->bindParam(':status', $this->status);
        
        if($stmt->execute()) {
            // Mettre à jour le nombre de copies du livre
            $book = new Book($this->conn);
            $book->id = $this->bookId;
            $book->updateCopies(false);
            
            return $this->id;
        }
        
        return false;
    }

    public function update() {
        $query = "UPDATE " . $this->table . " 
                  SET status = :status
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':status', $this->status);
        
        return $stmt->execute();
    }

    public function returnBook() {
        // Récupérer l'emprunt actuel
        $current = $this->readSingle();
        
        if($current['status'] == 'En cours' || $current['status'] == 'En retard') {
            $this->status = 'Retourné';
            
            if($this->update()) {
                // Réincrémenter les copies du livre
                $book = new Book($this->conn);
                $book->id = $current['bookId'];
                $book->updateCopies(true);
                
                return true;
            }
        }
        
        return false;
    }

    public function getByUser($userId) {
        $query = "SELECT e.*, b.title as bookTitle, b.author as bookAuthor,
                         b.categoryId, c.name as categoryName
                  FROM " . $this->table . " e
                  LEFT JOIN Books b ON e.bookId = b.id
                  LEFT JOIN Categories c ON b.categoryId = c.id
                  WHERE e.userId = ? AND e.status IN ('En cours', 'En retard')
                  ORDER BY e.returnDate ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $userId);
        $stmt->execute();
        
        return $stmt;
    }

    public function getLateLoans() {
        $query = "SELECT e.*, b.title as bookTitle, b.author as bookAuthor,
                         u.name as userName, u.email as userEmail,
                         DATEDIFF(CURDATE(), e.returnDate) as daysLate
                  FROM " . $this->table . " e
                  LEFT JOIN Books b ON e.bookId = b.id
                  LEFT JOIN Users u ON e.userId = u.id
                  WHERE e.status = 'En cours' AND e.returnDate < CURDATE()
                  ORDER BY e.returnDate ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function updateLateStatus() {
        $query = "UPDATE " . $this->table . " 
                  SET status = 'En retard'
                  WHERE status = 'En cours' AND returnDate < CURDATE()";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute();
    }
}