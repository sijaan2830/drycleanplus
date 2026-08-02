import firebase_admin
from firebase_admin import credentials, firestore

# --- CONFIGURATION ---
SERVICE_ACCOUNT_PATH = 'service-account.json'

def list_services():
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        
        print("--- CURRENT SERVICES IN FIRESTORE ---")
        docs = db.collection('services').get()
        for doc in docs:
            data = doc.to_dict()
            name = data.get('name', 'N/A')
            print(f"\nID: {doc.id}")
            print(f"Name: {name}")
            print(f"Items: {data.get('items', [])}")
            print("-" * 30)
            
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    list_services()
