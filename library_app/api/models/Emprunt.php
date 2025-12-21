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
        // CORRECTION : Définir borrowDate si vide
        if (empty($this->borrowDate)) {
            $this->borrowDate = date('Y-m-d H:i:s');
        }
        
        // Définir returnDate (14 jours après borrowDate)
        if (empty($this->returnDate)) {
            $this->returnDate = date('Y-m-d H:i:s', strtotime($this->borrowDate . ' +14 days'));
        }
        
        $query = "INSERT INTO " . $this->table . " 
                  SET id = :id, bookId = :bookId, userId = :userId,
                      borrowDate = :borrowDate, returnDate = :returnDate,
                      status = :status";
        
        $stmt = $this->conn->prepare($query);
        
        $this->id = uniqid();
        $this->status = $this->status ?? 'En cours';
        
        // DEBUG: Log des valeurs
        error_log("DEBUG Emprunt::create() values:");
        error_log("- id: " . $this->id);
        error_log("- bookId: " . $this->bookId);
        error_log("- userId: " . $this->userId);
        error_log("- borrowDate: " . $this->borrowDate);
        error_log("- returnDate: " . $this->returnDate);
        error_log("- status: " . $this->status);
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':bookId', $this->bookId);
        $stmt->bindParam(':userId', $this->userId);
        $stmt->bindParam(':borrowDate', $this->borrowDate);
        $stmt->bindParam(':returnDate', $this->returnDate);
        $stmt->bindParam(':status', $this->status);
        
        if($stmt->execute()) {
            // Mettre à jour le nombre de copies du livre
            try {
                require_once 'Book.php';
                $book = new Book($this->conn);
                $book->id = $this->bookId;
                $book->updateCopies(false);
                error_log("DEBUG: Copies mises à jour pour bookId: " . $this->bookId);
            } catch (Exception $e) {
                error_log("WARNING: Impossible de mettre à jour les copies: " . $e->getMessage());
            }
            
            return $this->id;
        } else {
            $errorInfo = $stmt->errorInfo();
            error_log("ERROR Emprunt::create() failed: " . print_r($errorInfo, true));
            return false;
        }
    }

    public function update() {
        $query = "UPDATE " . $this->table . " 
                  SET status = :status,
                      borrowDate = :borrowDate,
                      returnDate = :returnDate
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':status', $this->status);
        $stmt->bindParam(':borrowDate', $this->borrowDate);
        $stmt->bindParam(':returnDate', $this->returnDate);
        
        return $stmt->execute();
    }

    public function returnBook() {
        // Récupérer l'emprunt actuel
        $current = $this->readSingle();
        
        if($current['status'] == 'En cours' || $current['status'] == 'En retard') {
            $this->status = 'Retourné';
            $this->borrowDate = $current['borrowDate'];
            $this->returnDate = date('Y-m-d H:i:s'); // Date de retour actuelle
            
            if($this->update()) {
                // Réincrémenter les copies du livre
                try {
                    require_once 'Book.php';
                    $book = new Book($this->conn);
                    $book->id = $current['bookId'];
                    $book->updateCopies(true);
                    return true;
                } catch (Exception $e) {
                    error_log("ERROR returnBook: " . $e->getMessage());
                    return false;
                }
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