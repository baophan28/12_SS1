
                     README - MODULE PHÂN QUYỀN
-------------------------------------------------------------------
1.Tổng quan về module
-------------------------------------------------------------------
Module này là một script T-SQL hoàn chỉnh để thiết lập cơ sở dữ liệu
cho hệ thống Phân quyền dựa trên vai trò cho Microsoft SQL Server.

Mục tiêu của module là cung cấp một cấu trúc CSDL linh hoạt
và một API (dưới dạng Stored Procedure) để quản lý và kiểm tra
quyền hạn của người dùng trong ứng dụng.

Script này sẽ tự động:
+ Tạo các tables cần thiết cho việc phân quyền.
+ Chèn data seed cho các vai trò (Roles) và Quyền hạn (Permissions).
+ Tạo các tài khoản người dùng mẫu.
+ Thiết lập logic gán quyền chi tiết cho từng vai trò.
+ Cung cấp một Stored Procedure (sp_CheckUserPermission) làm điểm
  truy cập chính (API) cho Backend để kiểm tra quyền.
-------------------------------------------------------------------------
2.Key components
-------------------------------------------------------------------------
Module này bao gồm các đối tượng CSDL sau:
2.1. Bảng dữ liệu:
+   [users]:             Lưu trữ thông tin tài khoản (username, password hash...).
+   [roles]:             Định nghĩa các vai trò (VD: 'Admin', 'Manager').
+   [permissions]:       Định nghĩa các hành động (VD: 'MANAGE_PRODUCTS').
+   [role_user]:         Bảng nối N-M, gán người dùng vào các vai trò.
+   [permission_role]:   Bảng nối N-M, gán quyền hạn cho các vai trò.

2.2. Thủ tục Lưu trữ (Stored Procedure)
+   [sp_CheckUserPermission]:
    -   Mục đích: Là API duy nhất mà Backend cần gọi để xác thực một
      hành động của người dùng.
    -   Đầu vào: @InputUserID (INT), @PermissionName (NVARCHAR)
    -   Đầu ra: Bảng kết quả 1x1 với cột 'HasPermission' (1 = Có quyền, 0 = Không có quyền).

-----------------------------------------------------------------------
3.Installation
-----------------------------------------------------------------------
Để triển khai module này, hãy thực hiện các bước sau:
1 YÊU CẦU HỆ THỐNG
--------------------------------------------------------------------------
 Python (đã cài đặt và thêm vào Path).
 SQL Server (đã cài SQL Server Management Studio - SSMS).
 Trình duyệt web (Google Chrome / Edge).

2. CÀI ĐẶT THƯ VIỆN PYTHON
--------------------------------------------------------------------------
Mở Terminal (CMD hoặc PowerShell) tại thư mục dự án và chạy lệnh sau để cài các thư viện cần thiết:

    pip install flask flask-cors pyodbc

3. CẤU HÌNH DATABASE (SQL SERVER)
--------------------------------------------------------------------------
 Mở SQL Server Management Studio (SSMS).
 Tạo một Database mới tên là: ShopGiayDB
 Mở file Script SQL (đã tổng hợp các bảng, thủ tục và dữ liệu mẫu).
 Chạy (Execute) toàn bộ script đó để tạo bảng và dữ liệu.

4. CẤU HÌNH BACKEND (PYTHON)
--------------------------------------------------------------------------
 Mở file "app.py".
 Tìm dòng cấu hình: CONN_STR = (...)
 Tại dòng "SERVER=...", hãy sửa thành tên máy chủ SQL của bạn.
   (Cách xem tên server: Mở SSMS, tên server hiện ngay ở ô "Server name" lúc đăng nhập).
   
   Ví dụ: 
   SERVER=DESKTOP-O30DQG9\SQLEXPRESS;

5. CÁCH CHẠY ỨNG DỤNG
--------------------------------------------------------------------------
Bước 1: Khởi động Server Python
   - Mở Terminal tại thư mục dự án.
   - Gõ lệnh: 
     python app.py
   
   - Nếu thấy dòng chữ "Running on http://127.0.0.1:5000" là thành công.
   - TUYỆT ĐỐI KHÔNG TẮT CỬA SỔ NÀY TRONG QUÁ TRÌNH SỬ DỤNG.

Bước 2: Mở giao diện Web
   - Vào thư mục dự án, click đúp vào file "index.html" để mở trên trình duyệt.

6. DANH SÁCH TÀI KHOẢN MẪU (Mật khẩu mặc định: 123)
--------------------------------------------------------------------------
Hệ thống đã tạo sẵn các tài khoản với các quyền hạn khác nhau:

1. ADMIN (Quản trị viên)
   - User: admin_user
   - Pass: 123
   - Quyền: Xem danh sách nhân viên, Cắt quyền, Thêm quyền, Tạo user mới.

2. MANAGER (Quản lý)
   - User: manager_user
   - Pass: 123
   - Quyền: Xem danh sách đơn hàng, Gán Shipper cho đơn hàng.

3. SHIPPER (Giao hàng)
   - User: shipper_user
   - Pass: 123
   - Quyền: Xem đơn hàng được phân công, Cập nhật trạng thái (Đang giao -> Hoàn thành).

4. CUSTOMER (Khách hàng)
   - User: customer_user
   - Pass: 123
   - Quyền: Xem sản phẩm, Đặt mua hàng, Xem lịch sử đơn hàng của mình.

5. STAFF (Nhân viên)
   - User: staff_user
   - Pass: 123
   - Quyền: Tương tự Manager nhưng giới hạn báo cáo (tùy cấu hình).

7.CÁCH CHẠY UNIT TEST (KIỂM THỬ)
--------------------------------------------------------------------------
Để kiểm tra xem các API có hoạt động đúng logic không:
 Mở một Terminal mới.
 Gõ lệnh:
   python test_shop.py

 Nếu thấy hiện chữ "OK" và các dòng "[PASS]" nghĩa là hệ thống ổn định.

-----------------------------------------------------------------------
4.Usage
-----------------------------------------------------------------------

Module này được thiết kế để tích hợp với lớp Backend (VD: API C#, NodeJS, Python).

4.1. Quy trình Backend (Workflow)
1.  XÁC THỰC : Người dùng đăng nhập. Backend xác thực
    tên người dùng và mật khẩu (đã hash) với bảng [users].
2.  LẤY THÔNG TIN: Nếu đăng nhập thành công, lưu lại [UserID] của người
    dùng (thường là trong một JWT token hoặc Session).
3.  KIỂM TRA QUYỀN: Khi người dùng cố gắng thực hiện
    một hành động yêu cầu quyền (VD: Xóa sản phẩm), Backend sẽ:
    a. Lấy [UserID] từ token/session.
    b. Gọi Stored Procedure [sp_CheckUserPermission] với UserID
       và tên quyền (PermissionName) tương ứng.

4.2. Lệnh gọi Stored Procedure (API Call)
Để kiểm tra xem một người dùng có quyền hay không, thực thi lệnh sau:

    EXEC sp_CheckUserPermission
        @InputUserID = [ID của người dùng, ví dụ: 4],
        @PermissionName = N'[Tên quyền cần kiểm tra, ví dụ: MANAGE_PRODUCTS]'

4.3. Đọc Kết Quả
Stored Procedure sẽ trả về một tập kết quả (Result Set) duy nhất.
Backend của bạn cần đọc giá trị của cột `HasPermission`.

+   Kết quả `1`: Người dùng CÓ QUYỀN. Cho phép hành động tiếp tục.
+   Kết quả `0`: Người dùng KHÔNG CÓ QUYỀN. Backend nên trả về lỗi
                HTTP 403 (Forbidden).

-----------------------------------------------------------------------
5. SEED DATA
-----------------------------------------------------------------------
Script này tự động tạo các dữ liệu cơ bản sau:

5.1. Vai trò (Roles)
+   Admin:       Quản trị viên tối cao.
+   Manager:     Quản lý cửa hàng (sản phẩm, đơn hàng, nhân viên).
+   Staff:       Nhân viên (xử lý đơn hàng).
+   Customer:    Khách hàng (mua sắm).

5.2. Quyền hạn (Permissions) - Một số ví dụ
+   MANAGE_PRODUCTS:       Quản lý (thêm/sửa/xóa) sản phẩm.
+   MANAGE_ALL_ORDERS:     Xem và xử lý TẤT CẢ đơn hàng.
+   VIEW_OWN_ORDERS:       Chỉ xem đơn hàng của chính mình.
+   MANAGE_USERS:          Quản lý tài khoản người dùng (chỉ Admin).
+   VIEW_REPORTS:          Xem báo cáo doanh thu.

5.3. Tài khoản Mẫu
+   admin_user    (Role: Admin)
+   manager_user  (Role: Manager)
+   staff_user    (Role: Staff)
+   customer_user (Role: Customer)

**CẢNH BÁO BẢO MẬT:** Tất cả tài khoản mẫu đều dùng mật khẩu
`'hashed_password_placeholder'`. Đây KHÔNG phải là mật khẩu an toàn.
Bạn PHẢI cập nhật các mật khẩu này bằng một giá trị hash (ví dụ:
bcrypt, Argon2) được tạo từ ứng dụng Backend của bạn.

-----------------------------------------------------------------------
6. LƯU Ý BẢO MẬT (SECURITY NOTES)
-----------------------------------------------------------------------
+   HASHING: KHÔNG BAO GIỜ lưu mật khẩu dưới dạng plaintext
    Script này giả định rằng cột [PasswordHash] chứa
    mật khẩu đã được hash an toàn từ phía Backend.
+   DATABASE USER: Tài khoản CSDL mà ứng dụng Backend của bạn sử dụng
    để kết nối nên được cấp quyền ở mức tối thiểu
    . Tài khoản này chỉ cần quyền EXECUTE trên
    sp_CheckUserPermission` và SELECT/INSERT/UPDATE` trên các
    bảng nghiệp vụ (ví dụ: orders, products), không nhất thiết
    cần quyền `SELECT` trực tiếp trên các bảng [users] hoặc [roles].
----------------------------------------------------------------------







