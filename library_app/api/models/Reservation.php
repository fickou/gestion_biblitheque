<?php
// api/models/Reservation.php
class Reservation {
    private $conn;
    private $table = 'Reservations';

    public $id;
    public $bookId;
    public $userId;
    public $reserveDate;
    public $status;
    public $createdAt;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function read() {
        $query = "SELECT r.*, b.title as bookTitle, b.author as bookAuthor,
                         u.name as userName, u.matricule as userMatricule
                  FROM " . $this->table . " r
                  LEFT JOIN Books b ON r.bookId = b.id
                  LEFT JOIN Users u ON r.userId = u.id
                  ORDER BY r.createdAt DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function create() {
        $query = "INSERT INTO " . $this->table . " 
                  SET id = :id, bookId = :bookId, userId = :userId,
                      reserveDate = :reserveDate, status = :status";
        
        $stmt = $this->conn->prepare($query);
        
        $this->id = uniqid();
        $this->status = $this->status ?? 'En attente';
        $this->reserveDate = date('Y-m-d');
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':bookId', $this->bookId);
        $stmt->bindParam(':userId', $this->userId);
        $stmt->bindParam(':reserveDate', $this->reserveDate);
        $stmt->bindParam(':status', $this->status);
        
        return $stmt->execute();
    }

    public function updateStatus() {
        $query = "UPDATE " . $this->table . " 
                  SET status = :status
                  WHERE id = :id";
        
        $stmt = $this->conn->prepare($query);
        
        $stmt->bindParam(':id', $this->id);
        $stmt->bindParam(':status', $this->status);
        
        return $stmt->execute();
    }

    public function getPendingReservations() {
        $query = "SELECT r.*, b.title as bookTitle, b.author as bookAuthor,
                         u.name as userName, u.email as userEmail
                  FROM " . $this->table . " r
                  LEFT JOIN Books b ON r.bookId = b.id
                  LEFT JOIN Users u ON r.userId = u.id
                  WHERE r.status = 'En attente'
                  ORDER BY r.reserveDate ASC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        
        return $stmt;
    }

    public function cancelExpiredReservations() {
        $query = "UPDATE " . $this->table . " 
                  SET status = 'Expiré'
                  WHERE status = 'En attente' 
                  AND DATEDIFF(CURDATE(), reserveDate) > 7";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute();
    }
}