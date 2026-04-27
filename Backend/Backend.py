from flask import Flask, request, jsonify
from pymongo import MongoClient
import certifi
from flask_cors import CORS
from bson import json_util
import json
app = Flask(__name__)
CORS(app)

# --- 1. 数据库连接 ---
ca = certifi.where()
client = MongoClient(
    "mongodb+srv://admin:itmp123456@cluster0.bnw80ee.mongodb.net/?appName=Cluster0",
    tlsCAFile=ca
)
db = client.ITMP_Project
users_col = db.user_detail 
orders_col = db.order 

def parse_json(data):
    return json.loads(json_util.dumps(data))

# --- 2. 账号相关接口 (Register/Login/Role) ---

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if 'student_id' not in data:
        return jsonify({"message": "Missing student_id"}), 400
    if users_col.find_one({"student_id": data['student_id']}):
        return jsonify({"message": "User already exists"}), 400
    users_col.insert_one(data)
    return jsonify({"message": "Register success"}), 200

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    user = users_col.find_one({"student_id": data['student_id']})
    if not user or user['password'] != data['password']:
        return jsonify({"message": "Wrong password"}), 401
    return jsonify({
        "message": "Login success",
        "role": user.get('role', 'student'),
        "name": user.get('name', 'User')
    }), 200

@app.route('/api/user/update_role', methods=['POST'])
def update_role():
    data = request.get_json()
    result = users_col.update_one(
        {"student_id": data.get('student_id')},
        {"$set": {"role": data.get('role')}}
    )
    return jsonify({"msg": "success"}) if result.matched_count > 0 else (jsonify({"msg": "User not found"}), 404)

# Update User Info API (for Edit Profile Page)
@app.route('/api/user/update_info', methods=['POST'])
def update_user_profile():
    data = request.get_json()
    student_id = data.get('student_id')

    result = users_col.update_one(
        {"student_id": student_id},
        {"$set": {
            "name": data.get('name'),
            "password": data.get('password'),
            "contact": data.get('contact'),
            "dorm": data.get('dorm'),
        }}
    )
    return jsonify({"msg": "Profile updated"}) if result.matched_count > 0 else (jsonify({"msg": "User not found"}), 404)


# --- 3. 订单列表相关接口 ---

# 修改 API 9: 获取待接单列表
@app.route('/api/orders/pending', methods=['GET'])
def get_pending_orders():
    try:
        # 获取所有待接单
        pending_orders = list(orders_col.find({"status": "pending"}))
        
        for order in pending_orders:
            # 1. 计算价格 (你的阶梯规则)
            qty = int(order.get('parcel_qty', 0))
            price = qty * 2.0 if qty < 5 else qty * 1.0
            order['money_to_receive'] = price # 对应你朋友代码里的 money_to_receive

            # 2. 解决 Dorm: N/A 问题
            # 拿着订单里的 requester (学号) 去用户表找宿舍
            cust_id = order.get('requester')
            user_info = users_col.find_one({"student_id": cust_id}, {"_id": 0})
            if user_info:
                order['dorm'] = user_info.get('dorm', "N/A") # 填充宿舍信息
            else:
                order['dorm'] = "N/A"
                
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

# API 10: 加载客户资料
# ✨ 优化后的 API 10: 获取订单关联的客户详请
@app.route('/api/order/user_info', methods=['GET'])
def get_user_info():
    order_id = request.args.get('order_id')
    order_data = orders_col.find_one({"order_id": order_id}, {"_id": 0})
    
    if order_data:
        # 对应你的 MongoDB 字段: requester
        cust_id = order_data.get('requester')
        user_info = users_col.find_one({"student_id": cust_id}, {"_id": 0})
        
        # 重新计算一次价格确保万无一失
        qty = int(order_data.get('parcel_qty', 0))
        total_money = qty * 2.0 if qty < 5 else qty * 1.0
        
        # 合并所有数据
        res = {**order_data, **(user_info or {})}
        
        # 💡 强制把 requester 赋值给 'id'，对齐你的 ParcelPage controller
        res['id'] = cust_id 
        res['money_to_receive'] = total_money
        
        return jsonify(res), 200
    return jsonify({"msg": "Not found"}), 404

# API 12: 确认接单
@app.route('/api/runner/take', methods=['POST'])
def take_order():
    data = request.get_json()
    order_id = data.get('order_id')
    runner_id = data.get('runner_id')
    
    result = orders_col.update_one(
        {"order_id": order_id},
        {"$set": {"status": "accepted", "runner_id": runner_id}}
    )
    
    if result.matched_count > 0:
        return jsonify({"msg": "Order accepted"}), 200
    else:
        return jsonify({"msg": "Order not found"}), 404
    
@app.route('/api/runner/dropped', methods=['POST'])
def update_to_dropped():
    data = request.json
    order_id = data.get('order_id')
    
    if not order_id:
        return jsonify({"msg": "Missing order_id"}), 400
        
    # 将订单状态改为 dropped
    result = orders_col.update_one(
        {"order_id": order_id},
        {"$set": {"status": "dropped"}}
    )
    
    if result.modified_count > 0:
        return jsonify({"msg": "Status updated to dropped"}), 200
    return jsonify({"msg": "Order not found"}), 404

# --- 4. 启动函数 (必须放在最后面！) ---
if __name__ == '__main__':
    # host='0.0.0.0' 让你的安卓模拟器能通过 10.0.2.2 访问
    app.run(debug=True, host='0.0.0.0', port=5000)