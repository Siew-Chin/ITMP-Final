from flask import Flask, request, jsonify
from pymongo import MongoClient  # 导入数据库驱动
import certifi
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

app = Flask(__name__)

# --- 数据库连接配置 ---
# 粘贴你刚才在 Compass 用的那串连接字符串

import certifi
ca = certifi.where()
client = MongoClient(
    "mongodb+srv://admin:itmp123456@cluster0.bnw80ee.mongodb.net/?appName=Cluster0",
tlsCAFile=ca
                     )

db = client.ITMP_Project  # 你刚才建的数据库名
users_col = db.user_detail      # 你刚才建的集合名

# 注册接口
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    # 确保前端传了 student_id，否则后面会报错
    if 'student_id' not in data:
        return jsonify({"message": "Missing student_id"}), 400

    student_id = data['student_id']

    # 1. 检查用户是否已存在
    if users_col.find_one({"student_id": student_id}):
        return jsonify({"message": "User already exists"}), 400

    # 2. 插入新用户 (现在 data 里不包含 role)
    users_col.insert_one(data)
    return jsonify({"message": "Register success"}), 200

# 登录接口
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    student_id = data['student_id']
    password = data['password']

    # 3. 查找用户
    user = users_col.find_one({"student_id": student_id})

    if not user:
        return jsonify({"message": "User not found"}), 404

    # 4. 验证密码
    if user['password'] != password:
        return jsonify({"message": "Wrong password"}), 401

    # 5. 登录成功，把 role 也传回去给前端做跳转
    return jsonify({
        "message": "Login success",
        "role": user.get('role', 'student'), # 拿到角色
        "name": user.get('name', 'User')
    }), 200

@app.route('/api/user/update_role', methods=['POST'])
def update_role():
    data = request.get_json()
    student_id = data.get('student_id')
    chosen_role = data.get('role') # 接收 'student' 或 'runner'

    if not student_id or not chosen_role:
        return jsonify({"msg": "Error: Missing data"}), 400

    # 在数据库中找到对应的学号，并把 role 字段更新（或新增）进去
    result = users_col.update_one(
        {"student_id": student_id},
        {"$set": {"role": chosen_role}}
    )

    if result.matched_count > 0:
        return jsonify({
            "msg": "success",
            "student_id": student_id,
            "role": chosen_role
        }), 200
    else:
        return jsonify({"msg": "User not found"}), 404
    
    # ==================================================
# --- RUNNER APP ORDER ENDPOINTS (MERGED) ---
# ==================================================
from bson import json_util
import json

# Connect to the 'orders' collection in the Cloud Database
orders_col = db.order 

# Helper function to convert MongoDB data for Flutter
def parse_json(data):
    return json.loads(json_util.dumps(data))

# The route your Flutter screen is looking for!
@app.route('/api/orders/pending', methods=['GET'])
def get_pending_orders():
    try:
        # This searches the cloud database for pending orders
        pending_orders = list(orders_col.find({"status": "pending"}))
        return jsonify(parse_json(pending_orders)), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route('/api/orders/<order_id>/complete', methods=['PUT'])
def complete_order(order_id):
    try:
        # This searches for the specific order and changes its status to "completed"
        result = orders_col.update_one(
            {"order_id": order_id}, 
            {"$set": {"status": "completed"}}
        )
        
        if result.modified_count > 0:
            return jsonify({"message": "Order successfully completed!"}), 200
        else:
            return jsonify({"error": "Order not found or already completed"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)