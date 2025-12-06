import unittest
from unittest.mock import patch
from app import app # Import app flask của bạn

class TestShoesShopAPI(unittest.TestCase):

    def setUp(self):
        # Thiết lập client giả lập để test
        self.app = app.test_client()
        self.app.testing = True

    # --- TEST 1: ĐĂNG NHẬP (LOGIN) ---
    @patch('app.db.login') # Giả lập hàm db.login
    def test_login_success(self, mock_db_login):
        # 1. Chuẩn bị kết quả giả (Mock Data)
        mock_db_login.return_value = {
            "success": True,
            "user": {
                "UserID": 1,
                "Username": "admin_user",
                "RoleName": "Admin"
            }
        }

        # 2. Gọi API thật
        payload = {"username": "admin_user", "password": "123"}
        response = self.app.post('/api/login', json=payload)

        # 3. Kiểm tra kết quả (Assert)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json['Username'], 'admin_user')
        print("\n[PASS] Test Login Success")

    @patch('app.db.login')
    def test_login_fail(self, mock_db_login):
        # Giả lập đăng nhập sai
        mock_db_login.return_value = {"success": False, "message": "Sai pass"}

        response = self.app.post('/api/login', json={"username": "wrong", "password": "x"})
        
        self.assertEqual(response.status_code, 401)
        print("[PASS] Test Login Fail")

    # --- TEST 2: ADMIN TẠO USER ---
    @patch('app.db.create_user')
    def test_admin_create_user(self, mock_create):
        mock_create.return_value = {"success": True, "message": "Tạo thành công"}

        payload = {
            "username": "new_staff",
            "password": "123",
            "fullname": "Nhan Vien Moi",
            "role_name": "Staff"
        }
        response = self.app.post('/api/admin/create-user', json=payload)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json['success'])
        print("[PASS] Test Admin Create User")

    # --- TEST 3: CUSTOMER ĐẶT HÀNG ---
    @patch('app.db.create_order')
    def test_customer_create_order(self, mock_order):
        mock_order.return_value = {"success": True, "message": "OK"}

        payload = {
            "user_id": 5,
            "amount": 500000,
            "address": "Ha Noi",
            "note": "Giay Nike"
        }
        response = self.app.post('/api/create-order', json=payload)

        self.assertEqual(response.status_code, 200)
        print("[PASS] Test Customer Create Order")

    # --- TEST 4: MANAGER GÁN SHIPPER ---
    @patch('app.db.assign_shipper')
    def test_manager_assign_shipper(self, mock_assign):
        mock_assign.return_value = {"success": True, "message": "OK"}

        payload = {
            "current_user_id": 2, # Manager
            "order_id": 10,
            "shipper_id": 4,
            "address": "Da Nang"
        }
        response = self.app.post('/api/assign-shipper', json=payload)

        self.assertEqual(response.status_code, 200)
        print("[PASS] Test Manager Assign Shipper")

    # --- TEST 5: ADMIN LẤY DANH SÁCH USER ---
    @patch('app.db.get_all_users')
    def test_get_all_users(self, mock_get_users):
        # Giả lập danh sách trả về từ SQL
        mock_get_users.return_value = [
            {"UserID": 1, "Username": "admin", "RoleName": "Admin"},
            {"UserID": 2, "Username": "staff", "RoleName": "Staff"}
        ]

        response = self.app.get('/api/admin/users')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json), 2) # Phải trả về đúng 2 người
        print("[PASS] Test Get All Users")

if __name__ == '__main__':
    unittest.main()