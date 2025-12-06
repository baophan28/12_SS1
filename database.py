import pyodbc

class Database:
    def __init__(self, connection_string):
        self.conn_str = connection_string

    def get_connection(self):
        return pyodbc.connect(self.conn_str)

    def row_to_dict(self, cursor, row):
        return {col[0]: val for col, val in zip(cursor.description, row)}

   # --- AUTH ---
    def login(self, username, password): # <--- Thêm tham số password
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = """
                SELECT u.UserID, u.Username, r.RoleName 
                FROM users u
                JOIN role_user ru ON u.UserID = ru.UserID
                JOIN roles r ON ru.RoleID = r.RoleID
                WHERE u.Username = ? AND u.PasswordHash = ? AND u.IsActive = 1
            """
            cursor.execute(sql, (username, password)) # <--- Truyền cả password vào
            
            row = cursor.fetchone()
            if row:
                return {"success": True, "user": self.row_to_dict(cursor, row)}
            else:
                return {"success": False, "message": "Sai tên đăng nhập hoặc mật khẩu!"}
        except Exception as e:
            return {"success": False, "message": str(e)}
        finally:
            if 'conn' in locals(): conn.close()
    # --- DATA & SHIPPER ---
    def get_all_shipments(self):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = """
                SELECT s.ShipmentID, s.ShippingAddress as Address, 
                       s.ShipmentStatus as Status, s.Notes,
                       s.ShipperID as AssignedTo, u.Username as ShipperName
                FROM shipments s
                LEFT JOIN users u ON s.ShipperID = u.UserID
            """
            cursor.execute(sql)
            rows = cursor.fetchall()
            return [self.row_to_dict(cursor, row) for row in rows]
        except Exception as e: return []
        finally:
            if 'conn' in locals(): conn.close()

    def get_shippers(self):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = """
                SELECT u.UserID, u.Username FROM users u
                JOIN role_user ru ON u.UserID = ru.UserID
                JOIN roles r ON ru.RoleID = r.RoleID
                WHERE r.RoleName = 'Shipper' AND u.IsActive = 1
            """
            cursor.execute(sql)
            rows = cursor.fetchall()
            return [self.row_to_dict(cursor, row) for row in rows]
        except Exception as e: return []
        finally:
            if 'conn' in locals(): conn.close()

    def assign_shipper(self, current_user_id, order_id, shipper_id, address):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = "{CALL sp_AssignShipperToOrder (?, ?, ?, ?)}"
            cursor.execute(sql, (current_user_id, order_id, shipper_id, address))
            conn.commit()
            return {"success": True, "message": "OK"}
        except Exception as e: return {"success": False, "error": str(e)}
        finally:
            if 'conn' in locals(): conn.close()

    def update_shipment_status(self, current_user_id, shipment_id, new_status, note):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = "{CALL sp_UpdateShipmentStatus (?, ?, ?, ?)}"
            cursor.execute(sql, (current_user_id, shipment_id, new_status, note))
            conn.commit()
            return {"success": True, "message": "OK"}
        except Exception as e: return {"success": False, "error": str(e)}
        finally:
            if 'conn' in locals(): conn.close()

    # --- CUSTOMER (MUA HÀNG) ---
    def create_order(self, user_id, amount, address, note):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            sql = "{CALL sp_CreateOrder (?, ?, ?, ?)}"
            cursor.execute(sql, (user_id, amount, address, note))
            conn.commit()
            return {"success": True, "message": "OK"}
        except Exception as e: return {"success": False, "error": str(e)}
        finally:
            if 'conn' in locals(): conn.close()

    # --- ADMIN (QUẢN LÝ USER ) ---
    def get_all_users(self):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("{CALL sp_GetAllUsersWithRoles}")
            rows = cursor.fetchall()
            result = []
            for row in rows:
                result.append({
                    "UserID": row[0], "Username": row[1],
                    "FullName": row[2], "RoleName": row[3] if row[3] else "Chưa có quyền"
                })
            return result
        except Exception as e: return []
        finally:
            if 'conn' in locals(): conn.close()

    def revoke_role(self, target_user_id):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("{CALL sp_RevokeUserRole (?)}", (target_user_id,))
            conn.commit()
            return {"success": True}
        except Exception as e: return {"success": False, "error": str(e)}
        finally:
            if 'conn' in locals(): conn.close()

    def grant_role(self, target_user_id, role_name):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("{CALL sp_GrantUserRole (?, ?)}", (target_user_id, role_name))
            conn.commit()
            return {"success": True}
        except Exception as e: return {"success": False, "error": str(e)}
        finally:
            if 'conn' in locals(): conn.close()
            # --- ADMIN: TẠO USER MỚI ---
    def create_user(self, username, password, fullname, role_name):
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            # Gọi thủ tục vừa tạo
            sql = "{CALL sp_CreateUser (?, ?, ?, ?)}"
            cursor.execute(sql, (username, password, fullname, role_name))
            
            row = cursor.fetchone()
            conn.commit()
            
            if row:
                return {"success": bool(row[0]), "message": row[1]}
            return {"success": False, "message": "Lỗi không xác định"}
        except Exception as e:
            return {"success": False, "message": str(e)}
        finally:
            if 'conn' in locals(): conn.close()
