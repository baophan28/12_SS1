from flask import Flask, request, jsonify
from flask_cors import CORS
from database import Database

app = Flask(__name__)
CORS(app) 

# --- CẤU HÌNH KẾT NỐI ---
# !!! QUAN TRỌNG: Hãy thay 'SERVER=...' bằng tên máy của bạn !!!
CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=LOCALHOST;" 
    "DATABASE=dbtest1;"
    "Trusted_Connection=yes;"
)

db = Database(CONN_STR)

@app.route('/')
def home():
    return jsonify({"message": "ShopGiay API is Running!"})

# --- API CHUNG ---
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    # Gọi hàm login với cả username và password gửi từ web lên
    result = db.login(data.get('username'), data.get('password'))
    
    if result['success']:
        return jsonify(result), 200
    else:
        return jsonify(result), 401

@app.route('/api/shipments', methods=['GET'])
def get_shipments():
    return jsonify(db.get_all_shipments())

@app.route('/api/users', methods=['GET'])
def get_users():
    return jsonify(db.get_shippers())

# --- API MANAGER/SHIPPER ---
@app.route('/api/assign-shipper', methods=['POST'])
def assign_shipper():
    data = request.json
    res = db.assign_shipper(data.get('current_user_id'), data.get('order_id'), data.get('shipper_id'), data.get('address'))
    return jsonify(res), (200 if res['success'] else 403)

@app.route('/api/update-status', methods=['POST'])
def update_status():
    data = request.json
    res = db.update_shipment_status(data.get('current_user_id'), data.get('shipment_id'), data.get('new_status'), data.get('note'))
    return jsonify(res), (200 if res['success'] else 403)

# --- API CUSTOMER ---
@app.route('/api/create-order', methods=['POST'])
def create_order():
    data = request.json
    res = db.create_order(data.get('user_id'), data.get('amount'), data.get('address'), data.get('note'))
    return jsonify(res), (200 if res['success'] else 500)

# --- API ADMIN (QUẢN LÝ USER) ---
@app.route('/api/admin/users', methods=['GET'])
def admin_get_users():
    return jsonify(db.get_all_users())

@app.route('/api/admin/revoke-role', methods=['POST'])
def admin_revoke():
    data = request.json
    res = db.revoke_role(data.get('user_id'))
    return jsonify(res)

@app.route('/api/admin/grant-role', methods=['POST'])
def admin_grant():
    data = request.json
    res = db.grant_role(data.get('user_id'), data.get('role_name'))
    return jsonify(res)

@app.route('/api/admin/create-user', methods=['POST'])
def admin_create_user():
    data = request.json
    res = db.create_user(
        data.get('username'),
        data.get('password'),
        data.get('fullname'),
        data.get('role_name')
    )
    return jsonify(res)

if __name__ == '__main__':
    app.run(debug=True, port=5000)