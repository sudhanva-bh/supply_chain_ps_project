CREATE DATABASE supply_chain_db;
GO
USE supply_chain_db;
GO

-- Drop tables if they exist
DROP TABLE IF EXISTS StockTransactions;
DROP TABLE IF EXISTS PurchaseOrderItems;
DROP TABLE IF EXISTS PurchaseOrders;
DROP TABLE IF EXISTS InventoryItems;
DROP TABLE IF EXISTS ItemCategories;
DROP TABLE IF EXISTS Suppliers;
GO

-- 1. Suppliers
CREATE TABLE Suppliers (
    supplierID INT PRIMARY KEY,
    companyName VARCHAR(255) NOT NULL,
    contactEmail VARCHAR(255),
    region VARCHAR(100)
);

-- 2. ItemCategories
CREATE TABLE ItemCategories (
    categoryID INT PRIMARY KEY,
    categoryName VARCHAR(255) NOT NULL,
    description TEXT
);

-- 3. InventoryItems
CREATE TABLE InventoryItems (
    itemID INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    stockQuantity INT NOT NULL,
    unitPrice DECIMAL(10, 2) NOT NULL,
    categoryID INT,
    supplierID INT,
    CONSTRAINT FK_Inventory_Category FOREIGN KEY (categoryID) REFERENCES ItemCategories(categoryID),
    CONSTRAINT FK_Inventory_Supplier FOREIGN KEY (supplierID) REFERENCES Suppliers(supplierID)
);

-- 4. PurchaseOrders
CREATE TABLE PurchaseOrders (
    orderID INT PRIMARY KEY,
    orderDate DATETIME NOT NULL,
    totalCost DECIMAL(12, 2) NOT NULL,
    deliveryStatus VARCHAR(50)
);

-- 5. PurchaseOrderItems
CREATE TABLE PurchaseOrderItems (
    orderItemID INT PRIMARY KEY,
    orderID INT NOT NULL,
    itemID INT NOT NULL,
    quantityOrdered INT NOT NULL,
    negotiatedPrice DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_POI_Order FOREIGN KEY (orderID) REFERENCES PurchaseOrders(orderID),
    CONSTRAINT FK_POI_Item FOREIGN KEY (itemID) REFERENCES InventoryItems(itemID)
);

-- 6. StockTransactions
CREATE TABLE StockTransactions (
    transactionID INT PRIMARY KEY,
    itemID INT NOT NULL,
    quantityChanged INT NOT NULL,
    transactionType VARCHAR(50) NOT NULL, -- e.g., 'RESTOCK', 'SALE', 'ADJUSTMENT'
    timestamp DATETIME NOT NULL,
    CONSTRAINT FK_ST_Item FOREIGN KEY (itemID) REFERENCES InventoryItems(itemID)
);

-- Seed Data

INSERT INTO Suppliers (supplierID, companyName, contactEmail, region) VALUES
(1, 'Global Electronics Inc.', 'sales@globalelectronics.com', 'North America'),
(2, 'Asian Tech Components', 'orders@asiantech.com', 'Asia-Pacific'),
(3, 'Euro Supplies Ltd', 'contact@eurosupplies.eu', 'Europe');

INSERT INTO ItemCategories (categoryID, categoryName, description) VALUES
(1, 'Processors', 'Central Processing Units for desktops and servers'),
(2, 'Memory', 'RAM modules and sticks'),
(3, 'Storage', 'SSDs and HDDs');

INSERT INTO InventoryItems (itemID, name, stockQuantity, unitPrice, categoryID, supplierID) VALUES
(101, 'Intel Core i9-13900K', 150, 580.00, 1, 1),
(102, 'AMD Ryzen 9 7950X', 120, 550.00, 1, 2),
(103, 'Corsair Vengeance 32GB DDR5', 300, 150.00, 2, 1),
(104, 'Samsung 990 PRO 2TB SSD', 250, 180.00, 3, 2);

INSERT INTO PurchaseOrders (orderID, orderDate, totalCost, deliveryStatus) VALUES
(1001, '2023-10-01T10:00:00', 87000.00, 'DELIVERED'),
(1002, '2023-10-15T14:30:00', 45000.00, 'IN_TRANSIT');

INSERT INTO PurchaseOrderItems (orderItemID, orderID, itemID, quantityOrdered, negotiatedPrice) VALUES
(5001, 1001, 101, 100, 560.00),
(5002, 1001, 103, 200, 140.00),
(5003, 1002, 104, 250, 175.00);

INSERT INTO StockTransactions (transactionID, itemID, quantityChanged, transactionType, timestamp) VALUES
(9001, 101, 100, 'RESTOCK', '2023-10-05T09:00:00'),
(9002, 103, 200, 'RESTOCK', '2023-10-05T09:15:00'),
(9003, 101, -10, 'SALE', '2023-10-10T16:45:00'),
(9004, 104, 250, 'RESTOCK', '2023-10-20T11:00:00');
