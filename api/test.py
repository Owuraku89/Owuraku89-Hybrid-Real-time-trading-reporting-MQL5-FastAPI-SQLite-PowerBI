import requests
import json
import uvicorn
import threading
import time

# --- 1. Define the FastAPI Server Start Function ---
# (This is just to ensure the server is running when we test)
def start_server():
    # Note: This requires uvicorn to be installed
    uvicorn.run("main:app", host="127.0.0.1", port=8008, log_level="error")

# --- 2. Define the Test Request Function ---
def run_test():
    # Wait for the server to spin up
    time.sleep(3) 
    
    API_URL = "http://127.0.0.1:8008/trades/report/"
    
    # 2a. The exact data structure MQL5 sends
    test_data = {
        "symbol": "GBPUSD",
        "ticket": 99999,
        "order_type": "SELL",
        "volume": 0.25,
        "price": 1.2500,
        "timestamp": "2025-01-01T23:00:12Z"
    }
    
    # 2b. The headers MQL5 can reliably send (only Content-Type)
    headers = {
        'Content-Type': 'application/json'
        # Intentionally omitting 'accept'
    }

    print(f"--- Sending POST request with only 'Content-Type' header ---")
    print(f"URL: {API_URL}")
    print(f"Headers: {headers}")
    
    try:
        # Use json=data instead of data=json.dumps(data) for simplicity
        response = requests.post(API_URL, json=test_data, headers=headers)
        
        print("\n--- API Response ---")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            print("SUCCESS! FastAPI accepted the request with only the Content-Type header.")
            print("Response Body:", response.json())
        else:
            print(f"FAILURE! Status {response.status_code}. Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to the API. Ensure FastAPI is running on port 8008.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    # Stop the server after the test
    # This is tricky with uvicorn. In a real scenario, you'd run uvicorn separately.
    # For this script, we'll just let the test finish and ask the user to manually stop the server.

# --- 3. Execution ---
if __name__ == "__main__":
    # Start FastAPI in a separate thread
    # Note: In a real environment, you run 'uvicorn app:app' separately.
    # This threading approach is complex, let's simplify and rely on the user running it manually.
    
    # SIMPLIFIED INSTRUCTIONS:
    print("\n----------------------------------------------------------------------")
    print("ACTION REQUIRED: Ensure your FastAPI server is running in a separate terminal:")
    print("1. Navigate to: hybrid-trading-pipeline/api")
    print("2. Run: uvicorn app:app --reload")
    print("3. Then, run this script.")
    print("----------------------------------------------------------------------\n")
    
    # Wait for manual start (User action is required here)
    time.sleep(5) 
    run_test()