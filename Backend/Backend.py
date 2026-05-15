from fileinput import filename
import os
from tkinter import Menu
from unittest import result

from flask import Flask, request, jsonify
from pymongo import MongoClient
import certifi
from flask_cors import CORS
from bson import json_util
from bson import ObjectId 
import json
from datetime import datetime
import time
import uuid
from flask import Flask, send_from_directory
from stream_chat import StreamChat

app = Flask(__name__)
CORS(app)

# Database Connection
ca = certifi.where()
mongo_client = MongoClient("mongodb+srv://admin:itmp123456@cluster0.bnw80ee.mongodb.net/?appName=Cluster0", tlsCAFile=ca)
db = mongo_client.ITMP_Project
users_col = db.user_detail 
order_col = db.order  


#or file upload
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_FOLDER = os.path.join(BASE_DIR, 'static', 'proofs')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

#for chat
api_key = "659pk8bnxecv"
api_secret = "774u3vyq8sxqddhgjhgywqpftb8pc5xnq83dqrrdbknyf7wsd8yj3kta55f9r2b4"

stream_client = StreamChat(api_key, api_secret)

def generate_token(user_id):
    return stream_client.create_token(user_id)

#API 1: register
@app.route('/register', methods=['POST'])
def register():
    try:
        # 1. 接收 form-data
        name = request.form.get('name')
        student_id = request.form.get('student_id')
        password = request.form.get('password')
        contact = request.form.get('contact')
        dorm = request.form.get('dorm')

        if not all([name, student_id, password, contact, dorm]):
            return jsonify({"message": "Missing required fields"}), 400

        if db.user_detail.find_one({"student_id": student_id}):
            return jsonify({"message": "Student ID already registered"}), 409

        # 2. 处理头像上传
        profile_image_name = None
        if 'profile_image' in request.files:
            file = request.files['profile_image']
            if file.filename != '':
                ext = file.filename.split('.')[-1]
                profile_image_name = f"profile_{student_id}.{ext}"
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], profile_image_name)
                file.save(file_path)

        # 3. 构造用户对象（加入 profile_image）
        new_user = {
            "name": name,
            "student_id": student_id,
            "password": password,
            "contact": contact,
            "dorm": dorm,
            "profile_image": profile_image_name, # 保存文件名
            "role": "student",
            "total_earnings": 0.0,
            "created_at": datetime.utcnow()
        }

        db.user_detail.insert_one(new_user)
        
        # 4. (可选) 注册成功后顺便同步给 Stream Chat
        try:
            image_url = f"http://10.0.2.2:5000/static/proofs/{profile_image_name}" if profile_image_name else ""
            stream_client.upsert_user({
                "id": student_id,
                "name": name,
                "image": image_url
            })
        except:
            pass

        return jsonify({"message": "User registered successfully", "student_id": student_id}), 200

    except Exception as e:
        print(f"Register Error: {e}")
        return jsonify({"message": "Server error", "error": str(e)}), 500
    
# API 2: login
@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        password = data.get('password')

        # 1. 查找用户是否存在
        user = db.user_detail.find_one({"student_id": student_id})
        
        if not user:
            # 如果找不到该 ID，返回 404 (Not Found)
            return jsonify({"message": "Student ID not found"}), 404
        
        # 2. 如果 ID 存在，验证密码
        if user['password'] != password:
            # 如果密码不对，返回 401 (Unauthorized)
            return jsonify({"message": "Incorrect password"}), 401
            
        # 3. 验证通过
        return jsonify({
            "message": "Login success",
            "role": user.get('role', 'student'),
            "name": user.get('name', 'User')
        }), 200

    except Exception as e: 
        return jsonify({"error": str(e)}), 500

#API 3: create parcel order
@app.route('/api/parcel/create', methods=['POST'])
def create_parcel_order():
    try:
        data = request.json

        order_id = f"GRO-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

        user = db.user_detail.find_one({
            "student_id": data.get("requester_id")
        })

        # 自动决定 dropoff
        dropoff_point = (
            user.get("dorm", "N/A")
            if data.get("deliver_to_dorm")
            else data.get("dropoff_point")
        )

        new_order = {
            "order_id": order_id,
            "requester_id": data.get("requester_id"),
            "runner_id": None,
            "type": "Parcel",
            "status_code": 0,

            # business logic
            "item_price": float(data.get("item_price", 0)),
            "runner_profit": float(data.get("runner_profit", 0)),
            "total_to_collect": float(data.get("total_to_collect", 0)),

            # parcel details
            "parcel_qty": data.get("parcel_qty"),
            "parcel_details": data.get("parcel_details", ""),

            # 存真实 dorm
            "dropoff_point": dropoff_point, 

            "is_urgent": data.get("is_urgent", False),

            "created_at": datetime.utcnow(),

            "updates": [
                {
                    "status": "Order Placed",
                    "time": datetime.utcnow()
                }
            ]
        }

        db.order.insert_one(new_order)

        return jsonify({
            "message": "Parcel order created successfully",
            "order_id": order_id
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

#API4:GetProgress
@app.route('/api/order/tracking/<order_id>', methods=['GET'])
def get_order_tracking(order_id):
    order = db.order.find_one({"order_id": order_id})
    if order:
        return jsonify({
            "status_code": order.get('status_code', 0),
            "order_id": order.get('order_id'),
            "requester_id": order.get('requester_id'),
            "runner_id": order.get('runner_id', None),
            "proof_photo": order.get('proof_photo'),
            "item_price": order.get('item_price', 0),
            "runner_profit": order.get('runner_profit', 0),
            "total_to_collect": order.get('total_to_collect', 0),
        }), 200
    return jsonify({"msg": "Not found"}), 404

#API 5: Update Status 
@app.route('/api/order/update_status', methods=['POST'])
def update_status():
    try:
        data = request.json
        order_id = data.get('order_id')
        new_status_code = int(data.get('status_code'))
        runner_id = data.get('runner_id')

        # 1. 获取订单详情
        order = db.order.find_one({'order_id': order_id})
        if not order:
            return jsonify({"error": "Order not found"}), 404
        
        if order.get("is_cancelled") or int(order.get("status_code", 0)) == -1:
            return jsonify({"error": "Order has been cancelled"}), 400

        if new_status_code == 1 and int(order.get("status_code", 0)) != 0:
            return jsonify({"error": "Order is no longer available"}), 400

        # 2. 基本更新逻辑
        update_fields = {'status_code': new_status_code}
        if runner_id:
            update_fields['runner_id'] = runner_id
        
        # 处理超市订单输入金额的情况
        amount = data.get('amount')

        if amount is not None:
            item_price = float(amount)

            runner_profit = float(order.get('runner_profit', 5))

            total_to_collect = item_price + runner_profit

            update_fields['item_price'] = item_price
            update_fields['runner_profit'] = runner_profit
            update_fields['total_to_collect'] = total_to_collect
            
        db.order.update_one({'order_id': order_id}, {'$set': update_fields})

        # 3. 核心：结算收益 (Status 4)
        if new_status_code == 4 and runner_id:
            # 重新查一次最新的数据库订单情况，确保拿到刚才更新过的金额
            latest_order = db.order.find_one({'order_id': order_id})
            
            if latest_order.get('is_settled'):
                return jsonify({"message": "Already settled"}), 200

            try:
                profit_val = latest_order.get('runner_profit')
                final_earning = float(profit_val) if profit_val else 0.0
            except (ValueError, TypeError):
                final_earning = 0.0

            db.order.update_one(
                {'order_id': order_id}, 
                {'$set': {'is_settled': True, 'runner_profit': final_earning}} 
            )

            db.user_detail.update_one(
                {"student_id": runner_id},
                {"$inc": {"total_earnings": final_earning}}
            )
        return jsonify({"message": "Success"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#API 6: Upload Proof Photo and status update to 4
@app.route('/api/order/upload_proof', methods=['POST'])
def upload_proof():
    raw_order_id = request.form.get('order_id')
    order_id = raw_order_id.strip() if raw_order_id else None
    runner_id = request.form.get('runner_id')
    file = request.files.get('proof_image')
    
    print(f"DEBUG: Original ID: [{raw_order_id}]") 
    print(f"DEBUG: Cleaned ID: [{order_id}]")

    if not order_id or not file:
        return jsonify({"error": "Missing order_id or file"}), 400
    
    try:
        # 1. 定义文件名
        filename = f"proof_{order_id}.jpg"
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        
        # 2. 保存图片文件
        file.save(file_path)
        
        # 3. 生成可供 User 访问的 URL
        # 注意：User 访问时是通过这个链接下载图片的
        image_url = f"http://10.0.2.2:5000/static/proofs/{filename}"

        # 4. 更新数据库状态和图片路径
        result = db.order.update_one(
            {"order_id": order_id},  # 使用清理后的 ID
            {"$set": {
                "status_code": 4,
                "proof_photo": image_url,
                "status": "Dropped"
            }}
        )
        
        print(f"DEBUG: MongoDB Matched count: {result.matched_count}")
        
        if result.matched_count == 0:
            return jsonify({"error": f"Order {order_id} not found in database"}), 404

        return jsonify({"message": "Upload success", "url": image_url}), 200
    except Exception as e:
        print(f"ERROR: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
# API 6-1: Serve Proof Photos
@app.route('/static/proofs/<filename>')
def serve_proof(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# API 6-2: Generate Stream Chat Token
@app.route('/get_token/<user_id>', methods=['GET'])
def get_token(user_id):
    try:
        # 1. 从数据库获取真实的用户资料
        user_info = users_col.find_one({"student_id": user_id})
        
        # 默认值处理
        user_name = user_info.get("name", f"User {user_id}") if user_info else f"User {user_id}"
        
        # 2. 构造头像 URL (确保图片已在 UPLOAD_FOLDER)
        image_url = ""
        if user_info and user_info.get("profile_image"):
            image_url = f"http://10.0.2.2:5000/static/proofs/{user_info['profile_image']}"

        # 3. 将资料同步给 Stream Chat
        stream_client.upsert_user({
            "id": str(user_id),
            "name": user_name,
            "image": image_url, 
            "role": "admin"    
        })

        # 4. 生成 Token
        token = stream_client.create_token(str(user_id))
        
        return jsonify({"token": token})

    except Exception as e:
        print(f"STREAM ERROR: {e}")
        return jsonify({"error": str(e)}), 500

# API 7: Submit Feedback
@app.route('/api/order/feedback', methods=['POST'])
def submit_feedback():
    try:
        data = request.get_json()

        order_id = data.get("order_id")
        rating = data.get("rating")
        comment = data.get("comment")

        if not order_id or rating is None:
            return jsonify({"error": "Missing order_id or rating"}), 400

        order = db.order.find_one({"order_id": order_id})
        if not order:
            return jsonify({"error": "Order not found"}), 404

        feedback_data = {
            "rating": float(rating),
            "comment": comment,
            "submitted_at": datetime.utcnow()
        }

        # update order: store feedback inside order document
        db.order.update_one(
            {"order_id": order_id},
            {"$set": {
                "feedback": feedback_data
            }}
        )

        return jsonify({"msg": "success"}), 200

    except Exception as e:
        print(f"Feedback Error: {e}")
        return jsonify({"error": str(e)}), 500

# API 8: Order Summary
@app.route('/api/order/summary', methods=['GET'])
def get_order_summary():
    try:
        order_id = request.args.get("order_id")
        # 确保这里是从 db.order 拿数据
        order = db.order.find_one({"order_id": order_id})
        if not order:
            return jsonify({"error": "Order not found"}), 404

        user = db.user_detail.find_one({"student_id": order.get("requester_id")})

        response = {
            "order_id": order.get("order_id"),
            "user_id": order.get("requester_id"),
            "user_name": user.get("name") if user else "Unknown", # 加上这一行！
            "user_contact": user.get("contact") if user else "N/A",
            "runner_id": order.get("runner_id"),
            "status_code": order.get("status_code"),
            "item_price": order.get("item_price", 0),
            "runner_profit": order.get("runner_profit", 0),
            "total_to_collect": order.get("total_to_collect", 0),
        }
        return jsonify(response), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


#API 10 & 11: Get Food Menu
@app.route('/api/food/menu', methods=['GET'])
def get_all_menu():
    try:
        # 从 Menu collection 抓取所有档口信息
        menus = list(db.Menu.find({}, {"_id": 0})) 
        return jsonify(menus), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API 12: Create Food Order 
@app.route('/api/food/create', methods=['POST'])
def create_food_order():
    try:
        data = request.json
        # 1. 生成唯一 ID
        order_id = f"GRO-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

        user = db.user_detail.find_one({
            "student_id": data.get("requester_id")
        })

        # 自动决定 dropoff
        dropoff_point = (
            user.get("dorm", "N/A")
            if data.get("deliver_to_dorm")
            else data.get("dropoff_point")
        )
        # 2. 构造数据结构
        new_order = {
            "order_id": order_id,
            "requester_id": data.get("requester_id"),
            "runner_id": None,

            "type": "Food",
            "status_code": 0, # 0: 待接
            "stall_name": data.get("stall_name"),
            "food_name": data.get("food_name"),
            "dropoff_point": dropoff_point,
            "food_details": data.get("food_details"),
            "is_urgent": data.get("is_urgent", False),
            "item_price": float(data.get("item_price", 0)),
            "runner_profit": float(data.get("runner_profit", 0)),
            "total_to_collect": float(data.get("total_to_collect", 0)),
            "created_at": datetime.utcnow(),
            "updates": [{"status": "Order Placed", "time": datetime.utcnow()}]
        }
        
        # 3. 存入 MongoDB 的 order collection
        db.order.insert_one(new_order)
        return jsonify({"message": "Success", "order_id": order_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API 13: Create Pickup & Drop-off Order
@app.route('/api/ride/create', methods=['POST'])
def create_ride_order():
    try:
        data = request.json
        # 1. 生成 ID (RIDE-日期-随机)
        order_id = f"GRO-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

        user = db.user_detail.find_one({
            "student_id": data.get("requester_id")
        })

        pickup_point = (
            user.get("dorm")
            if data.get("_isPickupDorm")
            else data.get("pickup_point")
        )

        dropoff_point = (
            user.get("dorm")
            if data.get("_isDropOffDorm")
            else data.get("dropoff_point")
)
        # 2. 构造打车数据结构
        new_order = {
            "order_id": order_id,
            "requester_id": data.get("requester_id"),
            "runner_id": None,
            "dorm" : user.get("dorm", "N/A") if user else data.get("requester_dorm", "N/A"),
            "type": "Ride",             # 订单类型设为 Ride
            "status_code": 0,           # 0: 待接单
            "pickup_point": pickup_point,
            "dropoff_point": dropoff_point,
            "is_urgent": data.get("is_urgent", False),
            "item_price": float(data.get("item_price", 0)),
            "runner_profit": float(data.get("runner_profit", 0)),
            "total_to_collect": float(data.get("total_to_collect", 0)),
            "ride_details": data.get("ride_details"),
            "created_at": datetime.utcnow(),
            "updates": [
                {"status": "Finding a driver...", "time": datetime.utcnow()}
            ]
        }
        
        # 3. 插入 MongoDB (同样存入 order collection 方便统一管理)
        db.order.insert_one(new_order)
        
        return jsonify({
            "message": "Ride order created successfully",
            "order_id": order_id
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API 14: Get Shop List 
@app.route('/api/grocery/shops', methods=['GET'])
def get_grocery_shops():
    try:
        # 获取所有商店，只取名字
        shops = list(db.shops.find({}, {"_id": 0}))
        return jsonify(shops), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#API 15: Creat Grocery Order
@app.route('/api/grocery/create', methods=['POST'])
def create_grocery_order():
    try:
        data = request.json

        order_id = f"GRO-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

        user = db.user_detail.find_one({
            "student_id": data.get("requester_id")
        })

        # 自动决定 dropoff
        dropoff_point = (
            user.get("dorm", "N/A")
            if data.get("deliver_to_dorm")
            else data.get("dropoff_point")
        )

        new_order = {
            "order_id": order_id,
            "requester_id": data.get("requester_id"),
            "runner_id": None,

            "dorm": user.get("dorm", "N/A") if user else "N/A",

            "pickup_point": data.get("pickup_point"),

            "dropoff_point": dropoff_point,

            "type": "Grocery",
            "status_code": 0,

            "shop_name": data.get("shop_name"),

            "shopping_list": data.get("shopping_list"),

            "shopping_details": data.get("shopping_details"),

            "is_urgent": data.get("is_urgent", False),

            "created_at": datetime.utcnow(),

            "item_price": float(data.get("item_price", 0)),

            "runner_profit": float(data.get("runner_profit", 0)),

            "total_to_collect": float(data.get("total_to_collect", 0)),

            "updates": [
                {
                    "status": "Grocery Order Placed",
                    "time": datetime.utcnow()
                }
            ]
        }

        db.order.insert_one(new_order)

        return jsonify({
            "message": "Success",
            "order_id": order_id
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
# API 16: Create Item Order
@app.route('/api/item/create', methods=['POST'])
def create_item_order():
    data = request.get_json()
    order_id = f"ITEM-{datetime.now().strftime('%Y%m%d')}-{str(uuid.uuid4())[:4].upper()}"

    user = db.user_detail.find_one({
        "student_id": data.get("requester_id")
    })

    pickup_point = (
        user.get("dorm")
        if data.get("_isPickupDorm")
        else data.get("pickup_point")
    )

    dropoff_point = (
        user.get("dorm")
        if data.get("_isDropOffDorm")
        else data.get("dropoff_point")
    )

    new_order = {
        "order_id": order_id,
        "requester_id": data.get('requester_id'),
        "type": "Item",
        "parcel_qty": data.get('parcel_qty'),
        "item_description": data.get('item_description'),
        "pickup_point": pickup_point,
        "dropoff_point": dropoff_point,
        "notes": data.get('notes'),
        "item_details": data.get("item_details"),
        "item_price": float(data.get("item_price", 0)),
        "runner_profit": float(data.get("runner_profit", 0)),
        "total_to_collect": float(data.get("total_to_collect", 0)), # Fixed price per your sketch
        "status_code": 0,    # 0 = Available
        "created_at": datetime.utcnow()
    }
    db.order.insert_one(new_order)
    return jsonify({"msg": "Success", "order_id": order_id}), 201

# API 17: Runner menu get orders
@app.route('/api/runner/market', methods=['GET'])
def get_runner_market():
    try:
        # 只展示 status_code 为 0 (待接单) 的任务
        tasks = list(db.order.find({
            "status_code": 0, 
            "is_cancelled": {"$ne": True}}
            ))
        
        formatted_tasks = []
        for task in tasks:
            task['_id'] = str(task['_id']) # 强制转字符串防止红屏
            
            # 时间格式化处理
            if 'created_at' in task and isinstance(task['created_at'], datetime):
                task['created_at'] = task['created_at'].isoformat()
            else:
                task['created_at'] = datetime.now().isoformat()

            # 确保费用有默认值
            task['runner_profit'] = float(task.get('runner_profit', 0))
            task['total_to_collect'] = float(task.get('total_to_collect', 0))
            task['is_urgent'] = task.get('is_urgent', False)
                        
            formatted_tasks.append(task)
                
        return jsonify(formatted_tasks), 200
    except Exception as e:
        print(f"Market Error: {e}")
        return jsonify({"error": str(e)}), 500

def parse_json(data):
    return json.loads(json_util.dumps(data))


# API 18: Runner's Active Tasks
@app.route('/api/runner/tasks', methods=['GET'])
def get_runner_tasks():
    runner_id = request.args.get('runner_id')
    # Statuses 1 (Taken), 2 (Picking), 3 (Picked)
    current = list(db.order.find({
        "runner_id": runner_id, 
        "status_code": {"$in": [1, 2, 3]},
        "is_cancelled": {"$ne": True}
    }))
    return jsonify(parse_json(current)), 200

# API 19: calculate Earnings
@app.route('/api/runner/earnings', methods=['GET'])
def get_earnings():
    runner_id = request.args.get('runner_id')

    completed = list(order_col.find({
        "runner_id": runner_id,
        "status_code": 4
    }))

    total = 0
    today = 0

    today_date = datetime.utcnow().date()

    for task in completed:
        earning = float(task.get('runner_profit') or 0)
        total += earning

        created_at = task.get("created_at")

        if isinstance(created_at, datetime):
            if created_at.date() == today_date:
                today += earning

    return jsonify({
        "today_earning": today,
        "total_earning": total
    }), 200

#API 20: runner side get order detail
@app.route('/api/order/detail/<order_id>', methods=['GET'])
def get_order_detail(order_id):
    try:
        # 1. 先查订单
        order = db.order.find_one({"order_id": order_id})
        if not order:
            return jsonify({"error": "Order not found"}), 404

        # 2. 确定申请人的 ID (兼容不同接口存入时的 key)
        student_id = order.get("requester_id") or order.get("student_id")
        
        # 3. 去 user_detail 表查这个人的实时资料
        user = db.user_detail.find_one({"student_id": student_id})
        
        # 4. 整合数据返回
        response_data = {
            "order_id": order.get("order_id"),
            "requester_id": student_id,
            "status_code": order.get("status_code", 0),
            "type": order.get("type", "Parcel"),
            # 优先从 user 表拿最新的名字和电话，拿不到再从 order 表拿，最后给默认值
            "customer_name": user.get("name") if user else order.get("customer_name", "Unknown User"),
            "requester_contact": user.get("contact") if user else order.get("requester_contact", "N/A"),

            "pickup_point": order.get("pickup_point") or "Unknown Location",
            "dropoff_point": order.get("dropoff_point") or "Unknown Location",

            "food_name": order.get("food_name"),
            "stall_name": order.get("stall_name"),

            "food_details": order.get("food_details"),
            "parcel_details": order.get("parcel_details"),
            "ride_details": order.get("ride_details"),
            "item_details": order.get("item_details"),

            "parcel_qty": order.get("parcel_qty"),

            "shop_name": order.get("shop_name"),
            "shopping_details": order.get("shopping_details"),

            "is_urgent": order.get("is_urgent", False),

            "shopping_list": order.get("shopping_list") or order.get("item_description", "No details"),
            "item_price": float(order.get("item_price", 0)),
            "runner_profit": float(order.get("runner_profit", 0)),
            "total_to_collect": float(order.get("total_to_collect", 0)),
        }
        
        return jsonify(response_data), 200
    except Exception as e:
        print(f"Detail Error: {e}")
        return jsonify({"error": str(e)}), 500

# API 21: Feedback Received (Runner side)
@app.route('/api/feedback/received', methods=['GET'])
def get_feedback_received():
    try:
        user_id = request.args.get("user_id") # 这里的 user_id 对应 runner_id

        # 查询条件：runner_id 匹配，且 feedback 字段存在
        query = {
            "runner_id": user_id,
            "feedback": {"$exists": True}
        }
        
        # 在 orders 集合里找
        orders = list(db.order.find(query).sort("feedback.submitted_at", -1))

        result = []
        for o in orders:
            # 获取评价者（下单人）的信息
            fb = o.get("feedback", {})
            from_user = db.user_detail.find_one({"student_id": o.get("requester_id")})
            submitted_at = fb.get("submitted_at")

            result.append({
                "service_type": o.get("type"), # 从订单获取类型
                "rating": fb.get("rating"),
                "from_username": from_user.get("name") if from_user else o.get("requester_id"),
                "comment": fb.get("comment"),
                "timestamp": (
                    submitted_at.strftime("%Y-%m-%d %H:%M:%S")
                    if isinstance(submitted_at, datetime)
                    else str(submitted_at) if submitted_at else ""
                )
            })

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API 22: Feedback Sent (User side)
@app.route('/api/feedback/sent', methods=['GET'])
def get_feedback_sent():
    try:
        user_id = request.args.get("user_id") # 这里的 user_id 对应 requester_id
        if not user_id:
            return jsonify({"error": "user_id is required"}), 400

        query = {
            "requester_id": user_id,
            "feedback": {"$exists": True}
        }
        
        orders = list(db.order.find(query).sort("feedback.submitted_at", -1))

        result = []
        for o in orders:
            fb = o.get("feedback", {})
            submitted_at = fb.get("submitted_at")
            # 获取被评价者（Runner）的信息
            to_user = db.user_detail.find_one({"student_id": o.get("runner_id")})
            
            result.append({
                "service_type": o.get("type"),
                "rating": fb.get("rating"),
                "to_username": to_user.get("name") if to_user else o.get("runner_id"),
                "timestamp": (
                    submitted_at.strftime("%Y-%m-%d %H:%M:%S") 
                    if isinstance(submitted_at, datetime) 
                    else str(submitted_at) if submitted_at else ""
                )
            })

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#API 23: Update user profile
@app.route('/api/user/update_info', methods=['POST'])
def update_user_profile():
    try:
        # 1. 兼容性处理：如果前端传的是 JSON，用 request.get_json()；如果是 form-data，用 request.form
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form

        student_id = data.get('student_id')
        if not student_id:
            return jsonify({"msg": "student_id is required"}), 400

        # 2. 构造基础更新字典
        update_fields = {}
        
        # 定义哪些字段是允许更新的
        fields_to_check = ['name', 'password', 'contact', 'dorm']
        
        for field in fields_to_check:
            val = data.get(field)
            # 只有当前端传过来的值不是 None 且不是空字符串时，才更新该字段
            if val is not None and val.strip() != "":
                update_fields[field] = val.strip()

        # 3. 复用你的文件上传逻辑
        if 'profile_image' in request.files:
            file = request.files['profile_image']
            if file.filename != '':
                # 使用 uuid 或 student_id 防止文件名重复
                ext = file.filename.split('.')[-1]
                filename = f"profile_{student_id}.{ext}"
                file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(file_path)
                
                # 将图片路径或文件名存入数据库
                update_fields["profile_image"] = filename

        if not update_fields:
            return jsonify({"msg": "No changes detected"}), 200

        # 4. 执行数据库更新
        result = users_col.update_one(
            {"student_id": student_id},
            {"$set": update_fields}
        )

        if result.matched_count > 0:
            # 5. 同步更新 Stream Chat 资料
            try:
                # 准备同步到 Stream Chat 的数据
                stream_update_data = {"id": student_id}
                
                if "name" in update_fields:
                    stream_update_data["name"] = update_fields["name"]
                    
                # 核心：如果有新图片，同步图片 URL
                if "profile_image" in update_fields:
                    # 拼接成完整的公网/局域网访问路径
                    full_image_url = f"http://10.0.2.2:5000/static/proofs/{update_fields['profile_image']}"
                    stream_update_data["image"] = full_image_url

                # 调用 Stream SDK 更新用户资料
                if len(stream_update_data) > 1: # 除了 ID 还有其他东西才更新
                    stream_client.upsert_user(stream_update_data)
                
            except Exception as stream_err:
                print(f"Stream Sync Warning: {stream_err}")

            return jsonify({"msg": "Profile updated"})
        else:
            return jsonify({"msg": "User not found"}), 404

    except Exception as e:
        return jsonify({"msg": "Server error", "error": str(e)}), 500
    

# API 24: Get User Profile
@app.route('/api/user/profile', methods=['GET'])
def get_user_profile():
    try:

        student_id = request.args.get("student_id")

        if not student_id:
            return jsonify({"error": "Missing student_id"}), 400

        user = users_col.find_one(
            {"student_id": student_id},
            {"_id": 0, "password": 0}
        )

        if not user:
            return jsonify({"error": "User not found"}), 404

        return jsonify(user), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
# API 25: Get order history
@app.route('/api/orders/history/<student_id>', methods=['GET'])
def get_order_history(student_id):
    try:

        query = {
            "status_code": 4,   # 只拿 completed order
            "$or": [
                {"requester_id": student_id},
                {"runner_id": student_id}
            ]
        }

        orders = list(
            db.order.find(query).sort("created_at", -1)
        )

        result = []

        for o in orders:

            requester = db.user_detail.find_one({
                "student_id": o.get("requester_id")
            })

            runner = db.user_detail.find_one({
                "student_id": o.get("runner_id")
            })

            feedback = o.get("feedback", {})

            result.append({
                "order_id": o.get("order_id"),

                "type": o.get("type", "Unknown"),

                "created_at":
                    o.get("created_at").isoformat()
                    if isinstance(o.get("created_at"), datetime)
                    else "",

                "requester_id": o.get("requester_id"),

                "runner_id": o.get("runner_id"),

                "user_name":
                    requester.get("name")
                    if requester else "Unknown",

                "runner_name":
                    runner.get("name")
                    if runner else "Unknown",

                "rating":
                    feedback.get("rating", 0),

                "comment":
                    feedback.get("comment", "")
            })

        return jsonify(result), 200

    except Exception as e:
        print(f"History Error: {e}")
        return jsonify({"error": str(e)}), 500
    
# API 26 (结合版): 获取用户详细资料
@app.route('/api/user/get_info/<student_id>', methods=['GET'])
def get_user_info(student_id):
    try:
        user = users_col.find_one(
            {"student_id": student_id}, 
            {"_id": 0, "password": 0}
        )
        
        if not user:
            return jsonify({"message": "User not found"}), 404
        
        if user.get("profile_image"):
            user["image_url"] = f"http://10.0.2.2:5000/static/proofs/{user['profile_image']}"
        else:
            user["image_url"] = "" 

        return jsonify(user), 200

    except Exception as e:
        print(f"Get Profile Error: {e}")
        return jsonify({"message": "Server error", "error": str(e)}), 500
    

# API 27: Runner earning history
@app.route('/api/runner/earning_history', methods=['GET'])
def get_earning_history():
    runner_id = request.args.get('runner_id')

    completed = list(order_col.find({
        "runner_id": runner_id,
        "status_code": 4
    }).sort("created_at", -1))

    tasks = []
    total = 0
    today = 0
    today_date = datetime.utcnow().date()

    for task in completed:
        earning = float(task.get('runner_profit') or 0)
        total += earning

        created_at = task.get("created_at")
        is_today = False

        if isinstance(created_at, datetime):
            is_today = created_at.date() == today_date
            date_text = created_at.strftime("%Y-%m-%d %H:%M")
        else:
            date_text = str(created_at or "")

        if is_today:
            today += earning

        tasks.append({
            "task_type": task.get("task_type")
                or task.get("service_type")
                or task.get("order_type")
                or task.get("type")
                or "Task",
            "earning": earning,
            "date": date_text,
        })

    return jsonify({
        "today_earning": today,
        "total_earning": total,
        "tasks": tasks
    }), 200

# API 28: Runner Rating Status
@app.route('/api/runner/rating_status', methods=['GET'])
def get_runner_rating_status():
    try:
        runner_id = request.args.get("runner_id")
        if not runner_id:
            return jsonify({"error": "runner_id is required"}), 400

        completed_tasks = list(order_col.find({
            "runner_id": runner_id,
            "status_code": 4
        }))

        completed_task_count = len(completed_tasks)

        ratings = []
        for task in completed_tasks:
            feedback = task.get("feedback")
            if feedback and feedback.get("rating") is not None:
                ratings.append(float(feedback.get("rating")))

        average_rating = sum(ratings) / len(ratings) if ratings else None

        should_warn = (
            completed_task_count >= 5
            and completed_task_count <= 9
            and average_rating is not None
            and average_rating < 3.0
        )

        should_block = (
            completed_task_count >= 10
            and average_rating is not None
            and average_rating < 3.0
        )

        return jsonify({
            "completed_task_count": completed_task_count,
            "average_rating": average_rating,
            "should_warn": should_warn,
            "should_block": should_block
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# API 29: User's Current Orders 
@app.route('/api/user/current_orders', methods=['GET'])
def get_user_current_orders():
    try:
        requester_id = request.args.get("requester_id")
        if not requester_id:
            return jsonify({"error": "requester_id is required"}), 400

        orders = list(order_col.find({
            "requester_id": requester_id,
            "status_code": {"$lt": 4},
            "is_cancelled": {"$ne": True}
        }).sort("created_at", -1))

        result = []

        for order in orders:
            runner_id = order.get("runner_id")
            runner_name = "Waiting for runner"

            if runner_id:
                runner = users_col.find_one({"student_id": runner_id})
                runner_name = runner.get("name") if runner else runner_id

            result.append({
                "order_id": order.get("order_id"),
                "type": order.get("type", "order"),
                "status_code": order.get("status_code", 0),
                "runner_id": runner_id,
                "runner_name": runner_name,
                "total_to_collect": order.get("total_to_collect", 0),
            })

        return jsonify(result), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
#API 30: Cancel Order (only if not taken by runner yet)
@app.route('/api/order/cancel', methods=['POST'])
def cancel_order():
    try:
        data = request.json
        order_id = data.get("order_id")
        requester_id = data.get("requester_id")

        order = db.order.find_one({
            "order_id": order_id,
            "requester_id": requester_id
        })

        if not order:
            return jsonify({"error": "Order not found"}), 404

        if int(order.get("status_code", 0)) > 0:
            return jsonify({"error": "Order already taken, cannot cancel"}), 400

        db.order.update_one(
            {"order_id": order_id},
            {
                "$set": {
                    "status_code": -1,
                    "is_cancelled": True,
                    "cancelled_at": datetime.utcnow()
                }
            }
        )

        return jsonify({"message": "Order cancelled"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)