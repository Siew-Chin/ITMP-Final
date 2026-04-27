from flask import Flask, request, jsonify
from pymongo import MongoClient
import certifi
from flask_cors import CORS
from bson import json_util
import json
import time

app = Flask(__name__)
CORS(app)

# Database Connection
ca = certifi.where()
client = MongoClient("mongodb+srv://admin:itmp123456@cluster0.bnw80ee.mongodb.net/?appName=Cluster0", tlsCAFile=ca)
db = client.ITMP_Project
orders_col = db.order

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

# API 20: 获取详情 (Order Summary)
@app.route('/api/orderdetail/<order_id>', methods=['GET'])
def get_order_detail(order_id):
    order = orders_col.find_one({"order_id": order_id})
    return jsonify(parse_json(order)), 200

# API 5: 更新状态 (Update Progress)
@app.route('/api/order/update_status', methods=['POST'])
def update_status():
    data = request.get_json()
    order_id = data.get('order_id')
    next_status = data.get('next_status') # Key requested by teammate
    runner_id = data.get('runner_id')     # Used when taking order

    update_fields = {"status_code": next_status}
    if runner_id:
        update_fields["runner_id"] = runner_id

    orders_col.update_one({"order_id": order_id}, {"$set": update_fields})
    return jsonify({"msg": "updated"}), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)