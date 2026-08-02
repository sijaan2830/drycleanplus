import firebase_admin
from firebase_admin import credentials, firestore

# --- CONFIGURATION ---
SERVICE_ACCOUNT_PATH = 'service-account.json'

def update_database():
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Connected to Firestore successfully.")

        # DATA FOR WASH & IRONING RESTRUCTURE
        # Categorizing into 'Single Items' and 'Bundles'
        wash_ironing_data = {
            "name": "Wash & Ironing",
            "icon": "assets/icons/Laundry & Ironing.png",
            "description": "Professional wash & ironing with bundle savings.",
            "isActive": True,
            "order": 4,
            "items": [
                # --- SINGLE ITEMS ---
                {"name": "Shirt", "price": "£2.95", "category": "Single Items"},
                {"name": "T-Shirt", "price": "£2.50", "category": "Single Items"},
                {"name": "Trousers", "price": "£3.45", "category": "Single Items"},
                {"name": "Jeans", "price": "£3.95", "category": "Single Items"},
                {"name": "Dress", "price": "£5.95", "category": "Single Items"},
                {"name": "Jacket", "price": "£4.95", "category": "Single Items"},
                {"name": "Bed Sheets", "price": "£5.95", "category": "Single Items"},
                {"name": "Pillowcase", "price": "£1.95", "category": "Single Items"},
                
                # --- BUNDLES ---
                {"name": "10 Items Bundle (Save £4.50)", "price": "£25.00", "category": "Bundles"},
                {"name": "20 Items Bundle (Save £10.00)", "price": "£50.00", "category": "Bundles"},
                {"name": "30 Items Bundle (Save £20.00)", "price": "£74.00", "category": "Bundles"},
            ]
        }

        # Update the specific service record
        # Note: We use laundry_&_ironing to match the existing ID found earlier
        service_id = "laundry_&_ironing"
        db.collection('services').document(service_id).set(wash_ironing_data, merge=True)
        print(f"Successfully restructured: {wash_ironing_data['name']}")

        # ALSO UPDATE THE PREPAID PACK (Label as 'Each item')
        new_pack = {
            "name": "Wash & Ironing Bundle",
            "description": "Professional wash & ironing for any mixed items.",
            "order": 6,
            "isActive": True,
            "discounts": [
                {"count": "10", "label": "Each item", "old": "29.50", "new": "25.00", "off": "15%"},
                {"count": "20", "label": "Each item", "old": "59.00", "new": "50.00", "off": "15%"},
                {"count": "30", "label": "Each item", "old": "88.50", "new": "74.00", "off": "16%"},
            ]
        }
        db.collection('prepaid_packs').document("wash_ironing_mixed_pack").set(new_pack)
        print("Updated Prepaid Pack details.")

        print("\nAll tasks completed! Wash & Ironing is now categorized with bundles.")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    update_database()
