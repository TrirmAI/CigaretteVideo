import requests
import hashlib
import json

# Configuration
BASE_URL = "http://127.0.0.1:18080"
USERNAME = "admin"
PASSWORD = "admin"

def md5(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def test_api_list():
    session = requests.Session()
    
    # 1. Login
    login_url = f"{BASE_URL}/api/user/login"
    password_md5 = md5(PASSWORD)
    
    print(f"Logging in to {login_url}...")
    try:
        login_res = session.get(login_url, params={"username": USERNAME, "password": password_md5})
        if login_res.status_code != 200:
            print(f"Login failed: {login_res.status_code}")
            return

        login_data = login_res.json()
        access_token = login_data.get('data', {}).get('accessToken')
        
        if not access_token:
             print("Login failed: No accessToken")
             return

        print(f"Login successful!")
        
        # 2. Query List
        list_url = f"{BASE_URL}/api/cloud/record/list"
        headers = {'access-token': access_token}
        params = {
            'page': 1,
            'count': 10,
            'query': '',
            'stream': 'Police001' 
        }
        
        print(f"Querying list from {list_url} with params {params}...")
        list_res = session.get(list_url, headers=headers, params=params)
        
        print(f"List Response Code: {list_res.status_code}")
        try:
            data = list_res.json()
            print(json.dumps(data, indent=2, ensure_ascii=False))
        except:
            print(list_res.text)

    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    test_api_list()