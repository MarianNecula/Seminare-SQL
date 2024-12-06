-- Crearea bazei de date pentru exerciții
CREATE DATABASE IF NOT EXISTS transactions_triggers;
USE transactions_triggers;

-- Crearea tabelelor necesare pentru exerciții

-- Tabelul `customers` pentru gestionarea clienților
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(255),
    contact_name VARCHAR(255),
    country VARCHAR(255),
    purchase_count INT DEFAULT 0
);

-- Tabelul `products` pentru gestionarea produselor
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255),
    price DECIMAL(10, 2),
    stock INT
);

-- Tabelul `orders` pentru gestionarea comenzilor
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    quantity INT,
    order_status VARCHAR(50),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Tabelul `audit_log` pentru logarea modificărilor
CREATE TABLE IF NOT EXISTS audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action VARCHAR(50),
    description TEXT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exercițiu 1: Începe o tranzacție
-- Creăm o tranzacție, adăugăm un nou client în tabelul `customers` și efectuam un `ROLLBACK`.
-- Tranzacția nu va fi salvată deoarece se efectuează un `ROLLBACK`.
BEGIN;

INSERT INTO customers (customer_name, contact_name, country) 
VALUES ('Ion Popescu', 'Ion Popescu', 'Romania');

ROLLBACK;  -- Anulează modificările efectuate de tranzacție

-- Exercițiu 2: COMMIT într-o tranzacție
-- Adăugăm un client într-o tranzacție și folosim `COMMIT` pentru a salva modificările.
BEGIN;

INSERT INTO customers (customer_name, contact_name, country) 
VALUES ('Maria Ionescu', 'Maria Ionescu', 'Romania');

COMMIT;  -- Confirmă tranzacția și salvează modificările

-- Exercițiu 3: Folosirea ROLLBACK
-- Modificăm un preț într-o tranzacție, dar efectuam un `ROLLBACK` înainte ca tranzacția să fie salvată.
BEGIN;

UPDATE products 
SET price = price * 1.1
WHERE product_id = 1;

ROLLBACK;  -- Tranzacția este anulată, prețul nu va fi actualizat

-- Exercițiu 4: Blocarea unei tabele într-o tranzacție
-- Blocăm tabelul `products` pentru a-l modifica într-o tranzacție.
BEGIN;

LOCK TABLE products WRITE;

UPDATE products 
SET price = price * 1.1
WHERE product_id = 2;

COMMIT;  -- Salvează modificările și deblochează tabelul

-- Exercițiu 5: Tranzacție cu mai multe operațiuni
-- Modificăm prețul și stocul unui produs într-o singură tranzacție, folosind `COMMIT` pentru a confirma modificările.
BEGIN;

UPDATE products 
SET price = price * 1.05 
WHERE product_id = 1;

UPDATE products 
SET stock = stock - 10
WHERE product_id = 1;

COMMIT;

-- Exercițiu 6: Gestionarea erorilor într-o tranzacție
-- Dacă o eroare apare într-o tranzacție, utilizăm `ROLLBACK` pentru a anula toate modificările.
BEGIN;

UPDATE products 
SET price = price * 1.1
WHERE product_id = 1;

-- Această linie va provoca o eroare deoarece coloana 'nonexistent_column' nu există
UPDATE products 
SET nonexistent_column = 'value'
WHERE product_id = 1;

ROLLBACK;  -- Anulează întreaga tranzacție

-- Exercițiu 7: Tranzacție cu mai multe tabele
-- Modificăm două tabele într-o singură tranzacție, apoi confirmăm modificările cu un `COMMIT`.
BEGIN;

UPDATE orders 
SET order_status = 'Shipped' 
WHERE order_id = 10;

UPDATE customers 
SET customer_status = 'Active' 
WHERE customer_id = 10;

COMMIT;

-- Exercițiu 8: Tabel cu 3 modificări în tranzacție
-- Modificăm 3 tabele într-o tranzacție și confirmăm tranzacția cu `COMMIT`.
BEGIN;

UPDATE orders 
SET order_status = 'Shipped' 
WHERE order_id = 20;

UPDATE products 
SET price = price * 1.2
WHERE product_id = 5;

UPDATE customers 
SET country = 'USA'
WHERE customer_id = 5;

COMMIT;

-- Exercițiu 9: Utilizarea SAVEPOINT
-- Folosim `SAVEPOINT` pentru a salva un punct în tranzacție și apoi revenim la acel punct utilizând `ROLLBACK TO`.
BEGIN;

SAVEPOINT start_point;

UPDATE products 
SET price = price * 1.1
WHERE product_id = 3;

ROLLBACK TO start_point;  -- Revin la punctul salvat, modificările efectuate după acest punct sunt anulate

COMMIT;

-- Exercițiu 10: Anularea unei tranzacții cu UPDATE
-- Modificăm un preț într-o tranzacție și facem un `ROLLBACK` înainte de `COMMIT`.
BEGIN;

UPDATE products 
SET price = price * 1.1
WHERE product_id = 4;

ROLLBACK;  -- Anulează modificările efectuate

-- Exercițiu 11: Trigger pentru inserarea unui client
-- Acest trigger va loga într-un tabel `audit_log` acțiunea de inserare a unui client în `customers`.
DELIMITER //
CREATE TRIGGER after_customer_insert
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, description, action_time) 
  VALUES ('INSERT', CONCAT('Customer ', NEW.customer_name, ' added'), NOW());
END;
//
DELIMITER ;

-- Exercițiu 12: Trigger pentru actualizarea stocului
-- Acest trigger actualizează stocul unui produs atunci când se plasează o comandă.
DELIMITER //
CREATE TRIGGER after_order_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
  UPDATE products
  SET stock = stock - NEW.quantity
  WHERE product_id = NEW.product_id;
END;
//
DELIMITER ;

-- Exercițiu 13: Trigger înainte de inserare
-- Acest trigger previne inserarea unui produs cu un preț mai mare de 1000.
DELIMITER //
CREATE TRIGGER before_product_insert
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
  IF NEW.price > 1000 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price exceeds the maximum allowed value';
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 14: Trigger după actualizare
-- Acest trigger loghează modificările de preț într-un tabel de audit atunci când prețul unui produs se actualizează.
DELIMITER //
CREATE TRIGGER after_price_update
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  IF OLD.price != NEW.price THEN
    INSERT INTO audit_log (action, description, action_time) 
    VALUES ('UPDATE', CONCAT('Price changed from ', OLD.price, ' to ', NEW.price), NOW());
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 15: Trigger de ștergere a unui client
-- Acest trigger va șterge comenzile asociate cu un client atunci când acesta este șters din tabelul `customers`.
DELIMITER //
CREATE TRIGGER after_customer_delete
AFTER DELETE ON customers
FOR EACH ROW
BEGIN
  DELETE FROM orders 
  WHERE customer_id = OLD.customer_id;
END;
//
DELIMITER ;

-- Exercițiu 16: Trigger de validare a unui preț
-- Acest trigger previne inserarea unui preț negativ într-un produs.
DELIMITER //
CREATE TRIGGER before_product_insert_price_check
BEFORE INSERT ON products
FOR EACH ROW
BEGIN
  IF NEW.price < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price cannot be negative';
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 17: Trigger de logare a modificărilor
-- Acest trigger va loga orice actualizare într-un tabel `employees` într-un tabel de audit.
DELIMITER //
CREATE TRIGGER after_employee_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, description, action_time) 
  VALUES ('UPDATE', CONCAT('Employee ', OLD.employee_name, ' updated'), NOW());
END;
//
DELIMITER ;

-- Exercițiu 18: Trigger de incrementare a unui câmp
-- Acest trigger incrementează un câmp `purchase_count` într-un tabel `customers` atunci când un client plasează o comandă.
DELIMITER //
CREATE TRIGGER after_order_insert_increment
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
  UPDATE customers
  SET purchase_count = purchase_count + 1
  WHERE customer_id = NEW.customer_id;
END;
//
DELIMITER ;

-- Exercițiu 19: Trigger pentru validarea datelor
-- Acest trigger validează dacă numărul de telefon introdus într-un tabel `contacts` are exact 10 caractere.
DELIMITER //
CREATE TRIGGER before_contact_insert
BEFORE INSERT ON contacts
FOR EACH ROW
BEGIN
  IF NOT NEW.phone REGEXP '^[0-9]{10}$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Phone number must be 10 digits';
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 20: Trigger pentru prevenirea duplicării
-- Acest trigger previne inserarea unui client cu același email în tabelul `customers`.
DELIMITER //
CREATE TRIGGER before_customer_insert_duplicate_email
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM customers WHERE email = NEW.email) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Email already exists';
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 21: Tranzacție pentru crearea unei comenzi
-- Tranzacția creează o comandă și actualizează stocul produsului.
BEGIN;

INSERT INTO orders (customer_id, product_id, quantity, order_status) 
VALUES (1, 2, 5, 'Pending');

UPDATE products 
SET stock = stock - 5 
WHERE product_id = 2;

COMMIT;

-- Exercițiu 22: Tranzacție pentru actualizarea prețului
-- Tranzacția actualizează prețul și stocul unui produs și face un `ROLLBACK`.
BEGIN;

UPDATE products 
SET price = price * 1.2 
WHERE product_id = 3;

UPDATE products 
SET stock = stock - 2 
WHERE product_id = 3;

ROLLBACK;

-- Exercițiu 23: Tranzacție cu mai multe tabele implicate
-- Tranzacția actualizează datele în tabelele `orders` și `customers`.
BEGIN;

UPDATE orders 
SET order_status = 'Shipped' 
WHERE order_id = 15;

UPDATE customers 
SET purchase_count = purchase_count + 1 
WHERE customer_id = 15;

COMMIT;

-- Exercițiu 24: Trigger pentru prevenirea modificării unui client
-- Trigger care previne modificarea datelor unui client.
DELIMITER //
CREATE TRIGGER prevent_customer_update
BEFORE UPDATE ON customers
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Update not allowed for customers';
END;
//
DELIMITER ;

-- Exercițiu 25: Tranzacție care șterge date
-- Tranzacția șterge o comandă și un client din tabelele respective.
BEGIN;

DELETE FROM orders 
WHERE order_id = 10;

DELETE FROM customers 
WHERE customer_id = 10;

COMMIT;

-- Exercițiu 26: Trigger pentru validarea cantității într-o comandă
-- Trigger care validează că o comandă nu poate avea o cantitate mai mare decât stocul produsului.
DELIMITER //
CREATE TRIGGER validate_order_quantity
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
  DECLARE product_stock INT;

  SELECT stock INTO product_stock 
  FROM products 
  WHERE product_id = NEW.product_id;

  IF NEW.quantity > product_stock THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough stock';
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 27: Tranzacție pentru modificarea prețului
-- Tranzacția modifică prețul unui produs și face un `ROLLBACK`.
BEGIN;

UPDATE products 
SET price = price * 1.15 
WHERE product_id = 7;

ROLLBACK;

-- Exercițiu 28: Trigger pentru logarea ștergerii unui produs
-- Trigger care loghează într-un tabel de audit fiecare ștergere din tabelul `products`.
DELIMITER //
CREATE TRIGGER log_product_delete
AFTER DELETE ON products
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (action, description, action_time) 
  VALUES ('DELETE', CONCAT('Product ', OLD.product_name, ' deleted'), NOW());
END;
//
DELIMITER ;

-- Exercițiu 29: Trigger pentru actualizarea statusului unui produs
-- Trigger care actualizează statusul unui produs atunci când stocul ajunge la 0.
DELIMITER //
CREATE TRIGGER update_product_status
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  IF NEW.stock = 0 THEN
    UPDATE products 
    SET status = 'Out of Stock' 
    WHERE product_id = NEW.product_id;
  END IF;
END;
//
DELIMITER ;

-- Exercițiu 30: Tranzacție pentru anularea unei comenzi
-- Tranzacția anulează o comandă și returnează produsele în stoc.
BEGIN;

UPDATE orders 
SET order_status = 'Cancelled' 
WHERE order_id = 25;

UPDATE products 
SET stock = stock + 5 
WHERE product_id = 5;

COMMIT;
