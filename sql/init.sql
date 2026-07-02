CREATE DATABASE supply_chain_db;
GO
USE supply_chain_db;
GO

-- 1. Suppliers
CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY,
    CompanyName VARCHAR(255) NOT NULL,
    ContactEmail VARCHAR(255),
    Region VARCHAR(100)
);

-- 2. ItemCategories
CREATE TABLE ItemCategories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(255) NOT NULL,
    Description TEXT
);

-- 3. InventoryItems
CREATE TABLE InventoryItems (
    ItemID INT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    StockQuantity INT NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    CategoryID INT,
    SupplierID INT,
    CONSTRAINT FK_Inventory_Category FOREIGN KEY (CategoryID) REFERENCES ItemCategories(CategoryID),
    CONSTRAINT FK_Inventory_Supplier FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- 4. PurchaseOrders
CREATE TABLE PurchaseOrders (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME NOT NULL,
    TotalCost DECIMAL(12, 2) NOT NULL,
    DeliveryStatus VARCHAR(50)
);

-- 5. PurchaseOrderItems
CREATE TABLE PurchaseOrderItems (
    OrderItemID INT PRIMARY KEY,
    OrderID INT NOT NULL,
    ItemID INT NOT NULL,
    QuantityOrdered INT NOT NULL,
    NegotiatedPrice DECIMAL(10, 2) NOT NULL,
    CONSTRAINT FK_POI_Order FOREIGN KEY (OrderID) REFERENCES PurchaseOrders(OrderID),
    CONSTRAINT FK_POI_Item FOREIGN KEY (ItemID) REFERENCES InventoryItems(ItemID)
);

-- 6. StockTransactions
CREATE TABLE StockTransactions (
    TransactionID INT PRIMARY KEY,
    ItemID INT NOT NULL,
    QuantityChanged INT NOT NULL,
    TransactionType VARCHAR(50) NOT NULL, -- e.g., 'RESTOCK', 'SALE', 'ADJUSTMENT'
    Timestamp DATETIME NOT NULL,
    CONSTRAINT FK_ST_Item FOREIGN KEY (ItemID) REFERENCES InventoryItems(ItemID)
);

-- Seed Data

INSERT INTO Suppliers (SupplierID, CompanyName, ContactEmail, Region) VALUES
(1, 'Global Electronics Inc.', 'sales@globalelectronics.com', 'North America'),
(2, 'Asian Tech Components', 'orders@asiantech.com', 'Asia-Pacific'),
(3, 'Euro Supplies Ltd', 'contact@eurosupplies.eu', 'Europe');

INSERT INTO ItemCategories (CategoryID, CategoryName, Description) VALUES
(1, 'Processors', 'Central Processing Units for desktops and servers'),
(2, 'Memory', 'RAM modules and sticks'),
(3, 'Storage', 'SSDs and HDDs');

INSERT INTO InventoryItems (ItemID, Name, StockQuantity, UnitPrice, CategoryID, SupplierID) VALUES
(101, 'Intel Core i9-13900K', 150, 580.00, 1, 1),
(102, 'AMD Ryzen 9 7950X', 120, 550.00, 1, 2),
(103, 'Corsair Vengeance 32GB DDR5', 300, 150.00, 2, 1),
(104, 'Samsung 990 PRO 2TB SSD', 250, 180.00, 3, 2);

INSERT INTO PurchaseOrders (OrderID, OrderDate, TotalCost, DeliveryStatus) VALUES
(1001, '2023-10-01T10:00:00', 87000.00, 'DELIVERED'),
(1002, '2023-10-15T14:30:00', 45000.00, 'IN_TRANSIT');

INSERT INTO PurchaseOrderItems (OrderItemID, OrderID, ItemID, QuantityOrdered, NegotiatedPrice) VALUES
(5001, 1001, 101, 100, 560.00),
(5002, 1001, 103, 200, 140.00),
(5003, 1002, 104, 250, 175.00);

INSERT INTO StockTransactions (TransactionID, ItemID, QuantityChanged, TransactionType, Timestamp) VALUES
(9001, 101, 100, 'RESTOCK', '2023-10-05T09:00:00'),
(9002, 103, 200, 'RESTOCK', '2023-10-05T09:15:00'),
(9003, 101, -10, 'SALE', '2023-10-10T16:45:00'),
(9004, 104, 250, 'RESTOCK', '2023-10-20T11:00:00');
