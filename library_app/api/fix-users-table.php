<?php
// fix-reservations-table.php - VERSION CORRIGÉE
header("Content-Type: application/json");

try {
    $host = 'localhost';
    $dbname = 'bibliotheque_db';
    $username = 'root';
    $password = '';
    
    $conn = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $response = ['steps' => []];
    
    // Désactiver les vérifications FK
    $conn->exec("SET FOREIGN_KEY_CHECKS = 0");
    $response['steps'][] = "✓ FOREIGN_KEY_CHECKS désactivés";
    
    // 1. Trouver toutes les contraintes sur reservations
    $stmt = $conn->query("
        SELECT 
            TABLE_NAME,
            COLUMN_NAME,
            CONSTRAINT_NAME,
            REFERENCED_TABLE_NAME,
            REFERENCED_COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE REFERENCED_TABLE_NAME = 'reservations'
        AND TABLE_SCHEMA = '$dbname'
    ");
    
    $foreignKeys = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $response['foreign_keys'] = $foreignKeys;
    
    // 2. Supprimer temporairement les contraintes
    foreach ($foreignKeys as $fk) {
        try {
            $sql = "ALTER TABLE {$fk['TABLE_NAME']} DROP FOREIGN KEY {$fk['CONSTRAINT_NAME']}";
            $conn->exec($sql);
            $response['steps'][] = "✓ Contrainte {$fk['CONSTRAINT_NAME']} supprimée de {$fk['TABLE_NAME']}";
        } catch (Exception $e) {
            $response['steps'][] = "⚠️ Impossible de supprimer {$fk['CONSTRAINT_NAME']}: " . $e->getMessage();
        }
    }
    
    // 3. MODIFICATION IMPORTANTE: Vérifier si id est déjà clé primaire
    $stmt = $conn->query("SHOW INDEX FROM reservations WHERE Key_name = 'PRIMARY'");
    $primaryKey = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($primaryKey) > 0) {
        // id est déjà clé primaire, juste modifier le type
        $response['steps'][] = "✓ id est déjà clé primaire";
        
        // Modifier le type sans redéfinir PRIMARY KEY
        $conn->exec("ALTER TABLE reservations MODIFY COLUMN id INT AUTO_INCREMENT");
        $response['steps'][] = "✓ reservations.id modifié en INT AUTO_INCREMENT (type seulement)";
    } else {
        // id n'est pas clé primaire, ajouter PRIMARY KEY
        $conn->exec("ALTER TABLE reservations MODIFY COLUMN id INT AUTO_INCREMENT PRIMARY KEY");
        $response['steps'][] = "✓ reservations.id modifié en INT AUTO_INCREMENT PRIMARY KEY";
    }
    
    // 4. Modifier aussi les colonnes dans les tables enfants
    foreach ($foreignKeys as $fk) {
        try {
            // Vérifier si la colonne existe
            $stmt = $conn->query("SHOW COLUMNS FROM {$fk['TABLE_NAME']} LIKE '{$fk['COLUMN_NAME']}'");
            if ($stmt->rowCount() > 0) {
                // Vérifier si la colonne est déjà INT
                $stmt = $conn->query("DESCRIBE {$fk['TABLE_NAME']} {$fk['COLUMN_NAME']}");
                $colInfo = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($colInfo && stripos($colInfo['Type'], 'int') === false) {
                    // La colonne n'est pas INT, la convertir
                    $sql = "ALTER TABLE {$fk['TABLE_NAME']} MODIFY COLUMN {$fk['COLUMN_NAME']} INT";
                    $conn->exec($sql);
                    $response['steps'][] = "✓ {$fk['TABLE_NAME']}.{$fk['COLUMN_NAME']} converti en INT";
                } else {
                    $response['steps'][] = "✓ {$fk['TABLE_NAME']}.{$fk['COLUMN_NAME']} est déjà INT";
                }
            }
        } catch (Exception $e) {
            $response['steps'][] = "⚠️ Erreur avec {$fk['TABLE_NAME']}.{$fk['COLUMN_NAME']}: " . $e->getMessage();
        }
    }
    
    // 5. Recréer les contraintes
    foreach ($foreignKeys as $fk) {
        try {
            $sql = "ALTER TABLE {$fk['TABLE_NAME']} 
                    ADD CONSTRAINT {$fk['CONSTRAINT_NAME']} 
                    FOREIGN KEY ({$fk['COLUMN_NAME']}) 
                    REFERENCES reservations(id)";
            $conn->exec($sql);
            $response['steps'][] = "✓ Contrainte {$fk['CONSTRAINT_NAME']} recréée";
        } catch (Exception $e) {
            $response['steps'][] = "⚠️ Impossible de recréer {$fk['CONSTRAINT_NAME']}: " . $e->getMessage();
        }
    }
    
    // 6. Nettoyer les autres colonnes dans reservations
    $stmt = $conn->query("DESCRIBE reservations");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($columns as $col) {
        $colName = $col['Field'];
        
        // Colonnes qui devraient être INT
        $shouldBeInt = ['roleId', 'role_id', 'createdBy', 'updatedBy', 'created_by', 'updated_by'];
        
        if (in_array($colName, $shouldBeInt)) {
            try {
                // Vérifier le type actuel
                if (stripos($col['Type'], 'int') === false) {
                    // Vérifier si conversion possible
                    $stmt = $conn->query("
                        SELECT COUNT(*) as non_numeric 
                        FROM reservations 
                        WHERE `$colName` REGEXP '[^0-9]' 
                        AND `$colName` IS NOT NULL 
                        AND `$colName` != ''
                    ");
                    $result = $stmt->fetch(PDO::FETCH_ASSOC);
                    
                    if ($result['non_numeric'] == 0) {
                        $sql = "ALTER TABLE reservations MODIFY COLUMN `$colName` INT";
                        $conn->exec($sql);
                        $response['steps'][] = "✓ reservations.$colName modifié en INT";
                    } else {
                        // Conversion nécessaire
                        if ($colName == 'roleId' || $colName == 'role_id') {
                            // Convertir les rôles textuels
                            $conn->exec("
                                UPDATE reservations 
                                SET `$colName` = CASE 
                                    WHEN `$colName` = 'Administrateur' THEN 1
                                    WHEN `$colName` = 'Bibliothécaire' THEN 2
                                    WHEN `$colName` = 'Étudiant' THEN 3
                                    WHEN `$colName` = 'Enseignant' THEN 4
                                    ELSE 3
                                END
                                WHERE `$colName` REGEXP '[^0-9]'
                            ");
                            $conn->exec("ALTER TABLE reservations MODIFY COLUMN `$colName` INT");
                            $response['steps'][] = "✓ reservations.$colName converti et modifié en INT";
                        }
                    }
                }
            } catch (Exception $e) {
                $response['steps'][] = "⚠️ Erreur avec reservations.$colName: " . $e->getMessage();
            }
        }
    }
    
    // 7. Réactiver les vérifications FK
    $conn->exec("SET FOREIGN_KEY_CHECKS = 1");
    $response['steps'][] = "✓ FOREIGN_KEY_CHECKS réactivés";
    
    // 8. Vérifier la structure finale
    $stmt = $conn->query("DESCRIBE reservations");
    $response['final_structure'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // 9. Vérifier l'auto-incrément
    $response['debug'] = [
    'database' => $conn->query("SELECT DATABASE()")->fetchColumn(),
    'host' => $conn->query("SELECT @@hostname")->fetchColumn(),
    'port' => $conn->query("SELECT @@port")->fetchColumn(),
    'user' => $conn->query("SELECT USER()")->fetchColumn(),
];

    $stmt = $conn->query("SHOW TABLE STATUS LIKE 'reservations'");
    $tableStatus = $stmt->fetch(PDO::FETCH_ASSOC);
    $response['auto_increment'] = $tableStatus['Auto_increment'];
    
    $response['success'] = true;
    $response['message'] = "Table reservations corrigée avec succès !";
    
} catch (Exception $e) {
    // Réactiver FK en cas d'erreur
    try {
        $conn->exec("SET FOREIGN_KEY_CHECKS = 1");
    } catch (Exception $e2) {}
    
    $response = [
        "success" => false,
        "error" => $e->getMessage(),
        "file" => $e->getFile(),
        "line" => $e->getLine()
    ];
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>