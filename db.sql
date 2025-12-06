--USE [YourDatabaseName]; modulePQtest
set nocount on;
--create tables: 
create table roles (
    RoleID int primary key identity(1,1),
    RoleName nvarchar(50) not null unique,
    Description nvarchar(255)
);
go

create table users (
    UserID int primary key identity(1,1),
    Username nvarchar(50) not null unique,
    PasswordHash nvarchar(256) not null,
    FullName nvarchar(100),
    Email nvarchar(100) not null unique,
    PhoneNumber nvarchar(20),
    IsActive BIT not null DEFAULT 1,
    CreatedAt datetime not null DEFAULT getdate() 
);
Go
create table permissions (
    PermissionID int primary key identity(1,1),
    PermissionName nvarchar(100) not null unique,
    Description nvarchar(255)
);
Go


-- tạo bảng nối theo erd:
create table role_user (
    UserRoleID int primary key identity(1,1),
    UserID int not null,
    RoleID int not null,

    CONSTRAINT FK_role_user_users foreign key (UserID) references users(UserID) on delete cascade,
    constraint FK_role_user_roles FOREIGN KEY (RoleID) references roles(RoleID) on delete cascade,
    -- Đảm bảo một user không thể có 2 lần cùng 1 role
    CONSTRAINT UQ_role_user_User_Role UNIQUE (UserID, RoleID)
);
go

CREATE TABLE permission_role (
    RolePermissionID int primary key identity(1,1),
    RoleID int not null,
    PermissionID INT NOT NULL,

    constraint FK_permission_role_roles foreign key (RoleID) REFERENCES roles(RoleID) on delete cascade,
    constraint FK_permission_role_permissions foreign key (PermissionID) REFERENCES permissions(PermissionID) on delete cascade,

    -- Đảm bảo một role không thể có 2 lần cùng 1 permission
    constraint UQ_permission_role_Role_Permission unique (RoleID, PermissionID)
);
go
print N'Tạo bảng thành công';
go

-- chèn thêm seed data và thêm các roles:
insert into roles (RoleName, Description)
values
    ('Admin', 'Quản trị viên tối cao, có toàn bộ quyền hệ thống.'),
    ('Manager', 'Quản lý cửa hàng, quản lý sản phẩm, đơn hàng, nhân viên.'),
    ('Staff', 'Nhân viên bán hàng, xử lý đơn hàng và CSKH.'),
    ('Customer', 'Khách hàng mua sắm trên hệ thống.');
go

--Thêm permissions
print N'Đang thêm dữ liệu cho bảng [permissions]...';
INSERT INTO permissions (PermissionName, Description)
VALUES
    --Quyền về các products
    ('VIEW_PRODUCTS', 'Xem danh sách sản phẩm'),
    ('MANAGE_PRODUCTS', 'Thêm, sửa, xóa sản phẩm, quản lý kho hàng'),

    --Quyền về các đơn hàng
    ('CREATE_ORDER', 'Tạo đơn hàng mới'),
    ('VIEW_OWN_ORDERS', 'Xem lịch sử đơn hàng của chính mình'),
    ('MANAGE_ALL_ORDERS', 'Xem và xử lý tất cả đơn hàng (của Manager/Staff)'),

    -- Quyền về users
    ('VIEW_PROFILE', 'Xem thông tin cá nhân của mình'),
    ('MANAGE_PROFILE', 'Chỉnh sửa thông tin cá nhân của mình'),
    ('MANAGE_USERS', 'Quản lý tất cả tài khoản người dùng (của Admin)'),
    ('MANAGE_STAFF', 'Quản lý tài khoản nhân viên (của Manager)'),

    -- Quyền về các reports
    ('VIEW_REPORTS', 'Xem các báo cáo doanh thu, tồn kho'),

    -- Quyền về hệ thống
    ('MANAGE_ROLES_PERMISSIONS', 'Quản lý vai trò và quyền hạn (của Admin)');
go


-- logic gán quyền cho từng role: 
declare @AdminRoleID int = (select RoleID FROM roles where RoleName = 'Admin'); 
declare @ManagerRoleID int = (select RoleID from roles where RoleName = 'Manager');
declare @StaffRoleID Int = (select RoleID from roles where RoleName = 'Staff');
declare @CustomerRoleID Int = (select RoleID FROM roles where RoleName = 'Customer'); 

-- Gán quyền cho customer
insert into permission_role (RoleID, PermissionID)
select @CustomerRoleID, PermissionID FROM permissions
where PermissionName In (
    'VIEW_PRODUCTS',    
    'CREATE_ORDER',     
    'VIEW_OWN_ORDERS',  -- Xem đơn hàng của mình
    'VIEW_PROFILE',     
    'MANAGE_PROFILE'    
);

-- Gán quyền cho staff insert into
insert into permission_role (RoleID, PermissionID)
select @StaffRoleID, PermissionID from permissions
WHERE PermissionName IN (
    'VIEW_PRODUCTS',        
    'MANAGE_ALL_ORDERS',    -- Xử lý tất cả đơn hàng
    'VIEW_PROFILE',          
    'MANAGE_PROFILE'        
);

-- Gán quyền cho manager select  
insert into permission_role (RoleID, PermissionID)
select @ManagerRoleID, PermissionID From permissions
WHERE PermissionName in (
    'VIEW_PRODUCTS', 
    'MANAGE_PRODUCTS',      
    'MANAGE_ALL_ORDERS',
    'VIEW_REPORTS',         
    'MANAGE_STAFF',         
    'VIEW_PROFILE',
    'MANAGE_PROFILE'
);

-- Gán quyền cho admin,admin có tất cả các quyền select From
insert into permission_role (RoleID, PermissionID)
select @AdminRoleID, PermissionID From permissions;

print N'Gán quyền thành công'
go

--vì  password phải được tạo ở backend nên em chỉ để placeholder ở phần password insert into
-- tạo user mẫu và gán roles:
insert into users (Username, PasswordHash, FullName, Email) 
values
    ('admin_user', 'hashed_password_placeholder', 'em Huy chủ shop', 'admin@shopgiay.com'),
    ('manager_user', 'hashed_password_placeholder', 'Lê Quang An', 'manager.an@shopgiay.com'),
    ('staff_user', 'hashed_password_placeholder', 'Lê Văn Bình', 'staff.binh@shopgiay.com'),
    ('customer_user', 'hashed_password_placeholder', 'anh Cường','customer.cuong@gmail.com') 
Go

-- Gán Role cho User qua bảng [role_user] select RoleID from roles Where RoleName
insert Into role_user (UserID, RoleID)
values
    ((select UserID from users where Username = 'admin_user'), (select RoleID from roles Where RoleName = 'Admin')),
    ((select UserID from users where Username = 'manager_user'), (select RoleID from roles Where RoleName = 'Manager')),
    ((select UserID from users where Username = 'staff_user'), (select RoleID from roles Where RoleName = 'Staff')),
    ((select UserID from users where Username = 'customer_user'), (select RoleID from roles Where RoleName = 'Customer'));
go

print N'Tạo User mẫu hoàn tất.'; 
GO

--Logic kiểm tra các quyền:
print N'Đang tạo sp_CheckUserPermission...';
go

create procedure sp_CheckUserPermission
    @InputUserID int,
    @PermissionName nvarchar(100)
AS
begin
    SET nocount on; 

    DECLARE @HasPermission bit = 0; 

    -- Kiểm tra xem user có tồn tại, có đang active hay không?
    IF NOT EXISTS (SELECT 1 FROM users WHERE UserID = @InputUserID AND IsActive = 1)
    BEGIN
        SELECT @HasPermission AS HasPermission;
        RETURN;
    END;

    -- Kiểm tra quyền
    -- Logic: User -> role_user -> roles -> permission_role -> permissions
    if EXISTS (
        select 1
        from role_user as ur
        join permission_role as pr on ur.RoleID = pr.RoleID
        join permissions as p on pr.PermissionID = p.PermissionID
        where
            ur.UserID = @InputUserID
            AND p.PermissionName = @PermissionName
    )
    begin
        set @HasPermission = 1;
    END;

    select @HasPermission as HasPermission;
end;
go

print N'Stored Procedure đã được tạo.';
go

/* ===================================================================
   PHẦN 2: MODULE GIAO HÀNG (SHIPPING) 
   =================================================================== */

-- 1. TẠO BẢNG DỮ LIỆU
IF OBJECT_ID('orders', 'U') IS NULL
BEGIN
    CREATE TABLE orders (
        OrderID INT PRIMARY KEY IDENTITY(1,1),
        UserID INT NOT NULL, -- Khách hàng
        TotalAmount DECIMAL(18,2) DEFAULT 0,
        OrderDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_orders_users FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
    );
END
GO

IF OBJECT_ID('shipments', 'U') IS NULL
BEGIN
    CREATE TABLE shipments (
        ShipmentID INT PRIMARY KEY IDENTITY(1,1),
        OrderID INT NOT NULL,
        ShipperID INT NULL, 
        
        ShippingAddress NVARCHAR(255) NOT NULL,
        ShipmentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending', 
        AssignedAt DATETIME,
        DeliveredAt DATETIME,
        Notes NVARCHAR(500),

        CONSTRAINT FK_shipments_orders FOREIGN KEY (OrderID) REFERENCES orders(OrderID) ON DELETE CASCADE,
        CONSTRAINT FK_shipments_users FOREIGN KEY (ShipperID) REFERENCES users(UserID) 
    );
END
GO

-- 2. CẤU HÌNH PHÂN QUYỀN (RBAC)
IF NOT EXISTS (SELECT 1 FROM roles WHERE RoleName = 'Shipper')
BEGIN
    INSERT INTO roles (RoleName, Description)
    VALUES ('Shipper', N'Nhân viên giao hàng.');
END

IF NOT EXISTS (SELECT 1 FROM permissions WHERE PermissionName = 'VIEW_ASSIGNED_SHIPMENTS')
BEGIN
    INSERT INTO permissions (PermissionName, Description)
    VALUES 
        ('VIEW_ASSIGNED_SHIPMENTS', N'Xem đơn hàng được phân công'),
        ('UPDATE_SHIPMENT_STATUS', N'Cập nhật trạng thái giao hàng'),
        ('ASSIGN_SHIPPER', N'Phân công shipper (Manager/Staff)');
END
GO

DECLARE @ShipperRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Shipper');
INSERT INTO permission_role (RoleID, PermissionID)
SELECT @ShipperRoleID, PermissionID 
FROM permissions 
WHERE PermissionName IN ('VIEW_ASSIGNED_SHIPMENTS', 'UPDATE_SHIPMENT_STATUS')
AND PermissionID NOT IN (SELECT PermissionID FROM permission_role WHERE RoleID = @ShipperRoleID);

-- Gán quyền 'ASSIGN_SHIPPER' cho Manager và Staff
DECLARE @ManagerRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Manager');
DECLARE @StaffRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Staff');
DECLARE @AssignPermID INT = (SELECT PermissionID FROM permissions WHERE PermissionName = 'ASSIGN_SHIPPER');

INSERT INTO permission_role (RoleID, PermissionID)
SELECT RoleID, @AssignPermID
FROM roles 
WHERE RoleID IN (@ManagerRoleID, @StaffRoleID)
AND RoleID NOT IN (SELECT RoleID FROM permission_role WHERE PermissionID = @AssignPermID);
GO

-- 3. STORED PROCEDURES (LOGIC NGHIỆP VỤ)

IF OBJECT_ID('sp_AssignShipperToOrder', 'P') IS NOT NULL DROP PROC sp_AssignShipperToOrder;
GO

CREATE PROCEDURE sp_AssignShipperToOrder
    @CurrentUserID INT,        
    @TargetOrderID INT,        
    @TargetShipperID INT,    
    @Address NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    
    CREATE TABLE #PermCheck1 (HasPermission BIT);
    INSERT INTO #PermCheck1 EXEC sp_CheckUserPermission @CurrentUserID, 'ASSIGN_SHIPPER';
    
    IF (SELECT TOP 1 HasPermission FROM #PermCheck1) = 0
    BEGIN
        RAISERROR(N'Bạn không có quyền phân công giao hàng.', 16, 1);
        RETURN;
    END
    DROP TABLE #PermCheck1; 

    -- Validate Shipper
    IF NOT EXISTS (
        SELECT 1 FROM users u
        JOIN role_user ru ON u.UserID = ru.UserID
        JOIN roles r ON ru.RoleID = r.RoleID
        WHERE u.UserID = @TargetShipperID AND r.RoleName = 'Shipper' AND u.IsActive = 1
    )
    BEGIN
        RAISERROR(N'User không phải là Shipper hoặc đã bị khóa.', 16, 1);
        RETURN;
    END

    -- Logic gán đơn
    MERGE shipments AS target
    USING (SELECT @TargetOrderID AS OrderID) AS source
    ON (target.OrderID = source.OrderID)
    WHEN MATCHED THEN
        UPDATE SET 
            ShipperID = @TargetShipperID,
            ShippingAddress = @Address,
            AssignedAt = GETDATE(),
            ShipmentStatus = 'Pending'
    WHEN NOT MATCHED THEN
        INSERT (OrderID, ShipperID, ShippingAddress, AssignedAt, ShipmentStatus)
        VALUES (@TargetOrderID, @TargetShipperID, @Address, GETDATE(), 'Pending');
    
    PRINT N'Phân công thành công.';
END
GO

IF OBJECT_ID('sp_UpdateShipmentStatus', 'P') IS NOT NULL DROP PROC sp_UpdateShipmentStatus;
GO

CREATE PROCEDURE sp_UpdateShipmentStatus
    @CurrentUserID INT,     
    @ShipmentID INT,
    @NewStatus NVARCHAR(50),
    @Note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #PermCheck2 (HasPermission BIT);
    INSERT INTO #PermCheck2 EXEC sp_CheckUserPermission @CurrentUserID, 'UPDATE_SHIPMENT_STATUS';

    IF (SELECT TOP 1 HasPermission FROM #PermCheck2) = 0
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật trạng thái.', 16, 1);
        RETURN;
    END
    DROP TABLE #PermCheck2;

    -- Validate sở hữu
    IF NOT EXISTS (SELECT 1 FROM shipments WHERE ShipmentID = @ShipmentID AND ShipperID = @CurrentUserID)
    BEGIN
        RAISERROR(N'Bạn không được phân công đơn hàng này.', 16, 1);
        RETURN;
    END

    -- Update
    UPDATE shipments
    SET 
        ShipmentStatus = @NewStatus,
        Notes = @Note,
        DeliveredAt = CASE WHEN @NewStatus = 'Delivered' THEN GETDATE() ELSE DeliveredAt END
    WHERE ShipmentID = @ShipmentID;
    
    PRINT N'Cập nhật trạng thái thành công.';
END
GO

PRINT N'Cài đặt Module Giao Hàng hoàn tất.';
GO

--Thêm Role 
--USE [YourDatabaseName]; modulePQtest
set nocount on;
--create tables: 
create table roles (
    RoleID int primary key identity(1,1),
    RoleName nvarchar(50) not null unique,
    Description nvarchar(255)
);
go

create table users (
    UserID int primary key identity(1,1),
    Username nvarchar(50) not null unique,
    PasswordHash nvarchar(256) not null,
    FullName nvarchar(100),
    Email nvarchar(100) not null unique,
    PhoneNumber nvarchar(20),
    IsActive BIT not null DEFAULT 1,
    CreatedAt datetime not null DEFAULT getdate() 
);
Go
create table permissions (
    PermissionID int primary key identity(1,1),
    PermissionName nvarchar(100) not null unique,
    Description nvarchar(255)
);
Go


-- tạo bảng nối theo erd:
create table role_user (
    UserRoleID int primary key identity(1,1),
    UserID int not null,
    RoleID int not null,

    CONSTRAINT FK_role_user_users foreign key (UserID) references users(UserID) on delete cascade,
    constraint FK_role_user_roles FOREIGN KEY (RoleID) references roles(RoleID) on delete cascade,
    -- Đảm bảo một user không thể có 2 lần cùng 1 role
    CONSTRAINT UQ_role_user_User_Role UNIQUE (UserID, RoleID)
);
go

CREATE TABLE permission_role (
    RolePermissionID int primary key identity(1,1),
    RoleID int not null,
    PermissionID INT NOT NULL,

    constraint FK_permission_role_roles foreign key (RoleID) REFERENCES roles(RoleID) on delete cascade,
    constraint FK_permission_role_permissions foreign key (PermissionID) REFERENCES permissions(PermissionID) on delete cascade,

    -- Đảm bảo một role không thể có 2 lần cùng 1 permission
    constraint UQ_permission_role_Role_Permission unique (RoleID, PermissionID)
);
go
print N'Tạo bảng thành công';
go

-- chèn thêm seed data và thêm các roles:
insert into roles (RoleName, Description)
values
    ('Admin', 'Quản trị viên tối cao, có toàn bộ quyền hệ thống.'),
    ('Manager', 'Quản lý cửa hàng, quản lý sản phẩm, đơn hàng, nhân viên.'),
    ('Staff', 'Nhân viên bán hàng, xử lý đơn hàng và CSKH.'),
    ('Customer', 'Khách hàng mua sắm trên hệ thống.');
go

--Thêm permissions
print N'Đang thêm dữ liệu cho bảng [permissions]...';
INSERT INTO permissions (PermissionName, Description)
VALUES
    --Quyền về các products
    ('VIEW_PRODUCTS', 'Xem danh sách sản phẩm'),
    ('MANAGE_PRODUCTS', 'Thêm, sửa, xóa sản phẩm, quản lý kho hàng'),

    --Quyền về các đơn hàng
    ('CREATE_ORDER', 'Tạo đơn hàng mới'),
    ('VIEW_OWN_ORDERS', 'Xem lịch sử đơn hàng của chính mình'),
    ('MANAGE_ALL_ORDERS', 'Xem và xử lý tất cả đơn hàng (của Manager/Staff)'),

    -- Quyền về users
    ('VIEW_PROFILE', 'Xem thông tin cá nhân của mình'),
    ('MANAGE_PROFILE', 'Chỉnh sửa thông tin cá nhân của mình'),
    ('MANAGE_USERS', 'Quản lý tất cả tài khoản người dùng (của Admin)'),
    ('MANAGE_STAFF', 'Quản lý tài khoản nhân viên (của Manager)'),

    -- Quyền về các reports
    ('VIEW_REPORTS', 'Xem các báo cáo doanh thu, tồn kho'),

    -- Quyền về hệ thống
    ('MANAGE_ROLES_PERMISSIONS', 'Quản lý vai trò và quyền hạn (của Admin)');
go


-- logic gán quyền cho từng role: 
declare @AdminRoleID int = (select RoleID FROM roles where RoleName = 'Admin'); 
declare @ManagerRoleID int = (select RoleID from roles where RoleName = 'Manager');
declare @StaffRoleID Int = (select RoleID from roles where RoleName = 'Staff');
declare @CustomerRoleID Int = (select RoleID FROM roles where RoleName = 'Customer'); 

-- Gán quyền cho customer
insert into permission_role (RoleID, PermissionID)
select @CustomerRoleID, PermissionID FROM permissions
where PermissionName In (
    'VIEW_PRODUCTS',    
    'CREATE_ORDER',     
    'VIEW_OWN_ORDERS',  -- Xem đơn hàng của mình
    'VIEW_PROFILE',     
    'MANAGE_PROFILE'    
);

-- Gán quyền cho staff insert into
insert into permission_role (RoleID, PermissionID)
select @StaffRoleID, PermissionID from permissions
WHERE PermissionName IN (
    'VIEW_PRODUCTS',        
    'MANAGE_ALL_ORDERS',    -- Xử lý tất cả đơn hàng
    'VIEW_PROFILE',          
    'MANAGE_PROFILE'        
);

-- Gán quyền cho manager select  
insert into permission_role (RoleID, PermissionID)
select @ManagerRoleID, PermissionID From permissions
WHERE PermissionName in (
    'VIEW_PRODUCTS', 
    'MANAGE_PRODUCTS',      
    'MANAGE_ALL_ORDERS',
    'VIEW_REPORTS',         
    'MANAGE_STAFF',         
    'VIEW_PROFILE',
    'MANAGE_PROFILE'
);

-- Gán quyền cho admin,admin có tất cả các quyền select From
insert into permission_role (RoleID, PermissionID)
select @AdminRoleID, PermissionID From permissions;

print N'Gán quyền thành công'
go

--vì  password phải được tạo ở backend nên em chỉ để placeholder ở phần password insert into
-- tạo user mẫu và gán roles:
insert into users (Username, PasswordHash, FullName, Email) 
values
    ('admin_user', 'hashed_password_placeholder', 'em Huy chủ shop', 'admin@shopgiay.com'),
    ('manager_user', 'hashed_password_placeholder', 'Lê Quang An', 'manager.an@shopgiay.com'),
    ('staff_user', 'hashed_password_placeholder', 'Lê Văn Bình', 'staff.binh@shopgiay.com'),
    ('customer_user', 'hashed_password_placeholder', 'anh Cường','customer.cuong@gmail.com') 
Go

-- Gán Role cho User qua bảng [role_user] select RoleID from roles Where RoleName
insert Into role_user (UserID, RoleID)
values
    ((select UserID from users where Username = 'admin_user'), (select RoleID from roles Where RoleName = 'Admin')),
    ((select UserID from users where Username = 'manager_user'), (select RoleID from roles Where RoleName = 'Manager')),
    ((select UserID from users where Username = 'staff_user'), (select RoleID from roles Where RoleName = 'Staff')),
    ((select UserID from users where Username = 'customer_user'), (select RoleID from roles Where RoleName = 'Customer'));
go

print N'Tạo User mẫu hoàn tất.'; 
GO

--Logic kiểm tra các quyền:
print N'Đang tạo sp_CheckUserPermission...';
go

create procedure sp_CheckUserPermission
    @InputUserID int,
    @PermissionName nvarchar(100)
AS
begin
    SET nocount on; 

    DECLARE @HasPermission bit = 0; 

    -- Kiểm tra xem user có tồn tại, có đang active hay không?
    IF NOT EXISTS (SELECT 1 FROM users WHERE UserID = @InputUserID AND IsActive = 1)
    BEGIN
        SELECT @HasPermission AS HasPermission;
        RETURN;
    END;

    -- Kiểm tra quyền
    -- Logic: User -> role_user -> roles -> permission_role -> permissions
    if EXISTS (
        select 1
        from role_user as ur
        join permission_role as pr on ur.RoleID = pr.RoleID
        join permissions as p on pr.PermissionID = p.PermissionID
        where
            ur.UserID = @InputUserID
            AND p.PermissionName = @PermissionName
    )
    begin
        set @HasPermission = 1;
    END;

    select @HasPermission as HasPermission;
end;
go

print N'Stored Procedure đã được tạo.';
go

/* ===================================================================
   PHẦN 2: MODULE GIAO HÀNG (SHIPPING) 
   =================================================================== */

-- 1. TẠO BẢNG DỮ LIỆU
IF OBJECT_ID('orders', 'U') IS NULL
BEGIN
    CREATE TABLE orders (
        OrderID INT PRIMARY KEY IDENTITY(1,1),
        UserID INT NOT NULL, -- Khách hàng
        TotalAmount DECIMAL(18,2) DEFAULT 0,
        OrderDate DATETIME DEFAULT GETDATE(),
        CONSTRAINT FK_orders_users FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
    );
END
GO

IF OBJECT_ID('shipments', 'U') IS NULL
BEGIN
    CREATE TABLE shipments (
        ShipmentID INT PRIMARY KEY IDENTITY(1,1),
        OrderID INT NOT NULL,
        ShipperID INT NULL, 
        
        ShippingAddress NVARCHAR(255) NOT NULL,
        ShipmentStatus NVARCHAR(50) NOT NULL DEFAULT 'Pending', 
        AssignedAt DATETIME,
        DeliveredAt DATETIME,
        Notes NVARCHAR(500),

        CONSTRAINT FK_shipments_orders FOREIGN KEY (OrderID) REFERENCES orders(OrderID) ON DELETE CASCADE,
        CONSTRAINT FK_shipments_users FOREIGN KEY (ShipperID) REFERENCES users(UserID) 
    );
END
GO

-- 2. CẤU HÌNH PHÂN QUYỀN (RBAC)
IF NOT EXISTS (SELECT 1 FROM roles WHERE RoleName = 'Shipper')
BEGIN
    INSERT INTO roles (RoleName, Description)
    VALUES ('Shipper', N'Nhân viên giao hàng.');
END

IF NOT EXISTS (SELECT 1 FROM permissions WHERE PermissionName = 'VIEW_ASSIGNED_SHIPMENTS')
BEGIN
    INSERT INTO permissions (PermissionName, Description)
    VALUES 
        ('VIEW_ASSIGNED_SHIPMENTS', N'Xem đơn hàng được phân công'),
        ('UPDATE_SHIPMENT_STATUS', N'Cập nhật trạng thái giao hàng'),
        ('ASSIGN_SHIPPER', N'Phân công shipper (Manager/Staff)');
END
GO

DECLARE @ShipperRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Shipper');
INSERT INTO permission_role (RoleID, PermissionID)
SELECT @ShipperRoleID, PermissionID 
FROM permissions 
WHERE PermissionName IN ('VIEW_ASSIGNED_SHIPMENTS', 'UPDATE_SHIPMENT_STATUS')
AND PermissionID NOT IN (SELECT PermissionID FROM permission_role WHERE RoleID = @ShipperRoleID);

-- Gán quyền 'ASSIGN_SHIPPER' cho Manager và Staff
DECLARE @ManagerRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Manager');
DECLARE @StaffRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Staff');
DECLARE @AssignPermID INT = (SELECT PermissionID FROM permissions WHERE PermissionName = 'ASSIGN_SHIPPER');

INSERT INTO permission_role (RoleID, PermissionID)
SELECT RoleID, @AssignPermID
FROM roles 
WHERE RoleID IN (@ManagerRoleID, @StaffRoleID)
AND RoleID NOT IN (SELECT RoleID FROM permission_role WHERE PermissionID = @AssignPermID);
GO

-- 3. STORED PROCEDURES (LOGIC NGHIỆP VỤ)

IF OBJECT_ID('sp_AssignShipperToOrder', 'P') IS NOT NULL DROP PROC sp_AssignShipperToOrder;
GO

CREATE PROCEDURE sp_AssignShipperToOrder
    @CurrentUserID INT,        
    @TargetOrderID INT,        
    @TargetShipperID INT,    
    @Address NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    
    CREATE TABLE #PermCheck1 (HasPermission BIT);
    INSERT INTO #PermCheck1 EXEC sp_CheckUserPermission @CurrentUserID, 'ASSIGN_SHIPPER';
    
    IF (SELECT TOP 1 HasPermission FROM #PermCheck1) = 0
    BEGIN
        RAISERROR(N'Bạn không có quyền phân công giao hàng.', 16, 1);
        RETURN;
    END
    DROP TABLE #PermCheck1; 

    -- Validate Shipper
    IF NOT EXISTS (
        SELECT 1 FROM users u
        JOIN role_user ru ON u.UserID = ru.UserID
        JOIN roles r ON ru.RoleID = r.RoleID
        WHERE u.UserID = @TargetShipperID AND r.RoleName = 'Shipper' AND u.IsActive = 1
    )
    BEGIN
        RAISERROR(N'User không phải là Shipper hoặc đã bị khóa.', 16, 1);
        RETURN;
    END

    -- Logic gán đơn
    MERGE shipments AS target
    USING (SELECT @TargetOrderID AS OrderID) AS source
    ON (target.OrderID = source.OrderID)
    WHEN MATCHED THEN
        UPDATE SET 
            ShipperID = @TargetShipperID,
            ShippingAddress = @Address,
            AssignedAt = GETDATE(),
            ShipmentStatus = 'Pending'
    WHEN NOT MATCHED THEN
        INSERT (OrderID, ShipperID, ShippingAddress, AssignedAt, ShipmentStatus)
        VALUES (@TargetOrderID, @TargetShipperID, @Address, GETDATE(), 'Pending');
    
    PRINT N'Phân công thành công.';
END
GO

IF OBJECT_ID('sp_UpdateShipmentStatus', 'P') IS NOT NULL DROP PROC sp_UpdateShipmentStatus;
GO

CREATE PROCEDURE sp_UpdateShipmentStatus
    @CurrentUserID INT,     
    @ShipmentID INT,
    @NewStatus NVARCHAR(50),
    @Note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #PermCheck2 (HasPermission BIT);
    INSERT INTO #PermCheck2 EXEC sp_CheckUserPermission @CurrentUserID, 'UPDATE_SHIPMENT_STATUS';

    IF (SELECT TOP 1 HasPermission FROM #PermCheck2) = 0
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật trạng thái.', 16, 1);
        RETURN;
    END
    DROP TABLE #PermCheck2;

    -- Validate sở hữu
    IF NOT EXISTS (SELECT 1 FROM shipments WHERE ShipmentID = @ShipmentID AND ShipperID = @CurrentUserID)
    BEGIN
        RAISERROR(N'Bạn không được phân công đơn hàng này.', 16, 1);
        RETURN;
    END

    -- Update
    UPDATE shipments
    SET 
        ShipmentStatus = @NewStatus,
        Notes = @Note,
        DeliveredAt = CASE WHEN @NewStatus = 'Delivered' THEN GETDATE() ELSE DeliveredAt END
    WHERE ShipmentID = @ShipmentID;
    
    PRINT N'Cập nhật trạng thái thành công.';
END
GO

PRINT N'Cài đặt Module Giao Hàng hoàn tất.';
GO

-- Tạo đơn hàng mẫu và shipment mẫu
INSERT INTO orders (UserID, TotalAmount) VALUES (4, 500000);
INSERT INTO shipments (OrderID, ShippingAddress, ShipmentStatus) 
VALUES (1, N'123 Đường Láng, Hà Nội', 'Pending');

-- 1. Thủ tục lấy danh sách toàn bộ nhân viên và Role hiện tại
CREATE PROCEDURE sp_GetAllUsersWithRoles
AS
BEGIN
    SELECT 
        u.UserID, 
        u.Username, 
        u.FullName,
        r.RoleName
    FROM users u
    LEFT JOIN role_user ru ON u.UserID = ru.UserID
    LEFT JOIN roles r ON ru.RoleID = r.RoleID
    WHERE u.IsActive = 1;
END;
GO

-- 2. Thủ tục CẮT (XÓA) Role của nhân viên (Khi nhân viên nghỉ việc)
CREATE PROCEDURE sp_RevokeUserRole
    @TargetUserID INT
AS
BEGIN
    -- Xóa tất cả role của user này trong bảng role_user
    DELETE FROM role_user WHERE UserID = @TargetUserID;
END;
GO

-- 3. Thủ tục THÊM (GÁN) Role cho nhân viên
CREATE PROCEDURE sp_GrantUserRole
    @TargetUserID INT,
    @RoleName NVARCHAR(50)
AS
BEGIN
    DECLARE @RoleID INT = (SELECT RoleID FROM roles WHERE RoleName = @RoleName);
    
    IF @RoleID IS NULL
    BEGIN
        RAISERROR(N'Role không tồn tại', 16, 1);
        RETURN;
    END

    -- Trước khi thêm, xóa role cũ đi (để đảm bảo 1 người 1 role chính)
    DELETE FROM role_user WHERE UserID = @TargetUserID;

    -- Thêm role mới
    INSERT INTO role_user (UserID, RoleID) VALUES (@TargetUserID, @RoleID);
END;
GO

PRINT N'Cập nhật SQL Admin thành công!';


-- 1. Thêm tài khoản Shipper vào bảng users
INSERT INTO users (Username, PasswordHash, FullName, Email)
VALUES ('shipper_user', 'pass123', N'Nguyễn Văn Shipper', 'shipper@demo.com');

-- 2. Gán Role 'Shipper' cho tài khoản vừa tạo
DECLARE @ShipperRoleID INT = (SELECT RoleID FROM roles WHERE RoleName = 'Shipper');
DECLARE @UserID INT = (SELECT UserID FROM users WHERE Username = 'shipper_user');

INSERT INTO role_user (UserID, RoleID)
VALUES (@UserID, @ShipperRoleID);

-- Kiểm tra lại xem đã vào chưa
SELECT u.Username, r.RoleName 
FROM users u 
JOIN role_user ru ON u.UserID = ru.UserID 
JOIN roles r ON ru.RoleID = r.RoleID
WHERE r.RoleName = 'Shipper';

-- Cập nhật lại thủ tục sp_CreateUser để tự động điền Email
ALTER PROCEDURE sp_CreateUser
    @Username NVARCHAR(50),
    @Password NVARCHAR(256),
    @FullName NVARCHAR(100),
    @RoleName NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra tồn tại
    IF EXISTS (SELECT 1 FROM users WHERE Username = @Username)
    BEGIN
        SELECT 0 AS Success, N'Tên đăng nhập đã tồn tại!' AS Message;
        RETURN;
    END

    -- 2. Thêm User mới
    -- SỬA LỖI Ở ĐÂY: Tự động tạo Email theo công thức: username + @demo.com
    INSERT INTO users (Username, PasswordHash, FullName, Email)
    VALUES (@Username, @Password, @FullName, @Username + '@demo.com');

    DECLARE @NewUserID INT = SCOPE_IDENTITY();

    -- 3. Gán Role
    DECLARE @RoleID INT = (SELECT RoleID FROM roles WHERE RoleName = @RoleName);
    IF @RoleID IS NOT NULL
    BEGIN
        INSERT INTO role_user (UserID, RoleID) VALUES (@NewUserID, @RoleID);
    END

    SELECT 1 AS Success, N'Tạo tài khoản thành công!' AS Message;
END;
GO