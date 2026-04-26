from flask import Flask, request, jsonify
from pymongo import MongoClient
import certifi
from flask_cors import CORS
from bson import json_util
from bson import ObjectId 
import json
from datetime import datetime

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

if __name__ == '__main__':
    # host='0.0.0.0' 允许模拟器通过 10.0.2.2 访问
    app.run(debug=True, host='0.0.0.0', port=5000)