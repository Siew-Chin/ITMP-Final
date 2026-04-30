from flask import Flask, request, jsonify
from pymongo import MongoClient
import certifi
from flask_cors import CORS
from bson import json_util
from bson import ObjectId 
import json
from datetime import datetime
import time

app = Flask(__name__)
CORS(app)

# Database Connection
ca = certifi.where()
client = MongoClient("mongodb+srv://admin:itmp123456@cluster0.bnw80ee.mongodb.net/?appName=Cluster0", tlsCAFile=ca)
db = client.ITMP_Project
users_col = db.user_detail 
orders_col = db.order  

# --- 2. 账号接口 ---
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        user = users_col.find_one({"student_id": data['student_id']})
        if not user or user['password'] != data['password']:
            return jsonify({"message": "Wrong password"}), 401
        return jsonify({
            "message": "Login success",
            "role": user.get('role', 'student'),
            "name": user.get('name', 'User')
        }), 200
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

# --- 3. 接单接口 (Status 0 -> 1) ---
@app.route('/api/order/take', methods=['POST'])
def take_order():
    try:
        data = request.json
        order_id = data.get('order_id')
        new_status_code = data.get('status', 1) 
        runner_id = data.get('runner_id')

        result = orders_col.update_one(
            {'_id': ObjectId(order_id)},
            {'$set': {
                'status': 'accepted',
                'status_code': int(new_status_code),
                'runner_id': runner_id,
                'taken_at': datetime.now()
            }}
        )
        
        if result.matched_count > 0:
            return jsonify({"message": "Success", "msg": "Order accepted"}), 200
        return jsonify({"message": "Order not found"}), 404
    except Exception as e:
        return jsonify({"message": "Backend Error", "error": str(e)}), 500

# --- 4. 追踪接口 ---
@app.route('/api/order/tracking', methods=['GET'])
def get_order_tracking():
    order_id = request.args.get('id')
    try:
        order = orders_col.find_one({"_id": ObjectId(order_id)})
        if order:
            return jsonify({
                "status_code": order.get("status_code", 1),
                "order_id": str(order["_id"])
            }), 200
        return jsonify({"error": "Not found"}), 404
    except:
        return jsonify({"error": "Invalid ID"}), 400

# --- 5. 详情接口 (已补全完整字段并修复 Unknown 问题) ---
@app.route('/api/order/detail/<order_id>', methods=['GET'])
def get_order_detail(order_id):
    try:
        order = orders_col.find_one({"_id": ObjectId(order_id)})
        if order:
            student_id = order.get("requester_id")
            # 调试打印：如果这里打印的是 "BCD"，请确保 user_detail 里有 student_id 为 "BCD" 的人
            print(f"DEBUG: Finding user with student_id: {student_id}") 
            
            user = users_col.find_one({"student_id": student_id})
            
            # 整合订单与用户资料
            response_data = {
                "_id": str(order['_id']),
                "requester_id": user.get("name", "Unknown") if user else "Unknown",
                "dropoff_point": user.get("dorm", "N/A") if user else order.get("dropoff_point", "N/A"),
                "requester_contact": user.get("contact", "N/A") if user else order.get("requester_contact", "N/A"),
                "shop_name": order.get("shop_name", "N/A"),
                "shopping_list": order.get("shopping_list", []),
                "delivery_fee": order.get("delivery_fee", 3.0),
                "status_code": order.get("status_code", 1)
            }
            return jsonify(response_data), 200
        else:
            return jsonify({"error": "Order not found"}), 404
    except Exception as e:
        print(f"Detail Error: {e}")
        return jsonify({"error": str(e)}), 500

# --- 6. 更新状态接口 (核心业务逻辑) ---
@app.route('/api/order/update_status', methods=['POST'])
def update_status():
    try:
        data = request.json
        # 兼容 order_id 或 id 写入
        order_id = data.get('order_id') or data.get('id') 
        
        if not order_id:
            return jsonify({"message": "Missing order ID"}), 400

        # 确保转为 int，防止前端传字符串导致逻辑错误
        try:
            new_status_code = int(data.get('status_code'))
        except (TypeError, ValueError):
            return jsonify({"message": "Invalid status_code"}), 400

        amount = data.get('amount', "")

        # 构建更新字典
        update_fields = {'status_code': new_status_code}
        
        if amount:
            update_fields['receipt_amount'] = amount
            
        # 状态描述映射
        status_map = {
            1: "Accepted",      # 刚接单
            2: "Picking-up",    # 正在去店里
            3: "Picked-up",     # 已取货
            4: "Completed"      # 已送达
        }
        
        if new_status_code in status_map:
            update_fields['status'] = status_map[new_status_code]

        # 如果是状态 4，记录完成时间
        if new_status_code == 4:
            update_fields['completed_at'] = datetime.now()

        # 执行数据库更新
        result = orders_col.update_one(
            {'_id': ObjectId(order_id)},
            {'$set': update_fields}
        )

        if result.matched_count > 0:
            print(f"Success: Order {order_id} status updated to {new_status_code}")
            return jsonify({
                "message": "Status updated", 
                "current_status_code": new_status_code
            }), 200
        else:
            return jsonify({"message": "Order not found"}), 404
            
    except Exception as e:
        print(f"Update Status Error: {e}")
        return jsonify({"error": str(e)}), 500

# --- 7. 市场列表接口 ---
@app.route('/api/runner/market', methods=['GET'])
def get_runner_market():
    try:
        # 只展示 status_code 为 0 (待接单) 的任务
        tasks = list(orders_col.find({"status_code": 0}))
        
        formatted_tasks = []
        for task in tasks:
            task['_id'] = str(task['_id']) # 强制转字符串防止红屏
            
            # 时间格式化处理
            if 'created_at' in task and isinstance(task['created_at'], datetime):
                task['created_at'] = task['created_at'].isoformat()
            else:
                task['created_at'] = datetime.now().isoformat()

            # 确保费用有默认值
            if 'total_price' not in task:
                task['total_price'] = task.get('delivery_fee', 3.0)
            
            formatted_tasks.append(task)
                
        return jsonify(formatted_tasks), 200
    except Exception as e:
        print(f"Market Error: {e}")
        return jsonify({"error": str(e)}), 500

def parse_json(data):
    return json.loads(json_util.dumps(data))

# --- USER SIDE APIS ---

# API 16: 发布代送订单 (Create Item Order)
@app.route('/api/item/create', methods=['POST'])
def create_item_order():
    data = request.get_json()
    order_id = f"ITEM{int(time.time())}"
    new_order = {
        "order_id": order_id,
        "requester_id": data.get('student_id'),
        "type": "Item",
        "parcel_qty": data.get('parcel_qty'),
        "item_description": data.get('item_description'),
        "pickup_point": data.get('pickup_point'),
        "dropoff_point": data.get('dropoff_point'),
        "notes": data.get('notes'),
        "total_price": 5.0, # Fixed price per your sketch
        "status_code": 0,    # 0 = Available
        "created_at": time.time()
    }
    orders_col.insert_one(new_order)
    return jsonify({"msg": "Success", "order_id": order_id}), 201

# API 4: 获取实时进度 (Get Progress)
@app.route('/api/order/tracking', methods=['GET'])
def get_tracking():
    order_id = request.args.get('order_id')
    order = orders_col.find_one({"order_id": order_id})
    if order:
        return jsonify({"status_code": order.get('status_code', 0)}), 200
    return jsonify({"msg": "Not found"}), 404

# --- RUNNER SIDE APIS ---

# API 17: 获取任务大厅 (Market)
@app.route('/api/runner/market', methods=['GET'])
def get_market():
    # Shows all tasks that haven't been taken yet (Status 0)
    available = list(orders_col.find({"status_code": 0}).sort("created_at", -1))
    return jsonify(parse_json(available)), 200

# API 18: 获取当前任务 (Runner's Active Tasks)
@app.route('/api/runner/tasks', methods=['GET'])
def get_runner_tasks():
    runner_id = request.args.get('runner_id')
    # Statuses 1 (Taken), 2 (Picking), 3 (Picked)
    current = list(orders_col.find({
        "runner_id": runner_id, 
        "status_code": {"$in": [1, 2, 3]}
    }))
    return jsonify(parse_json(current)), 200

# API 19: 计算总收益 (Earnings)
@app.route('/api/runner/earnings', methods=['GET'])
def get_earnings():
    runner_id = request.args.get('runner_id')
    # Sum only Status 4 (Dropped/Completed)
    completed = list(orders_col.find({"runner_id": runner_id, "status_code": 4}))
    total = sum(task.get('total_price', 0) for task in completed)
    return jsonify({"Total earning": total}), 200


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)