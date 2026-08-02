import firebase_admin
from firebase_admin import credentials, firestore

# --- CONFIGURATION ---
SERVICE_ACCOUNT_PATH = 'service-account.json'

def sync_services():
    try:
        # Initialize Firebase Admin
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("Connected to Firestore successfully.")

        services_data = [
            {
                "id": "dry_clean",
                "name": "Dry Clean",
                "icon": "assets/icons/dry cleaning.png",
                "description": "Professional cleaning for suits, formal wear, ladies items, and wedding specialties.",
                "order": 1,
                "isActive": True,
                "items": [
                    {"name": "2 piece suit", "price": "£18.95", "category": "Suits"},
                    {"name": "3 piece suit", "price": "£21.90", "category": "Suits"},
                    {"name": "Trousers", "price": "£8.50", "category": "Menswear"},
                    {"name": "Jackets", "price": "£9.50", "category": "Menswear"},
                    {"name": "Designer Jacket", "price": "£10.20", "category": "Menswear"},
                    {"name": "Waistcoat", "price": "£5.65", "category": "Menswear"},
                    {"name": "Silk tie", "price": "£5.55", "category": "Menswear"},
                    {"name": "Cashmere jumper", "price": "£9.95", "category": "Menswear"},
                    {"name": "Ladies plain dress", "price": "£15.65", "category": "Ladies Wear"},
                    {"name": "Evening / Silk dress", "price": "£18.25", "category": "Ladies Wear"},
                    {"name": "Long coat", "price": "£19.95", "category": "Ladies Wear"},
                    {"name": "Blouse", "price": "£7.95", "category": "Ladies Wear"},
                    {"name": "Skirt", "price": "£7.95", "category": "Ladies Wear"},
                    {"name": "Skirt, pleated", "price": "£9.45", "category": "Ladies Wear"},
                    {"name": "Wedding Dress Offer (Cleaned & Boxed)", "price": "£180.00", "category": "Wedding"},
                    {"name": "Wedding Dress Specialists", "price": "from £120.00", "category": "Wedding"},
                ]
            },
            {
                "id": "duvets_bedding",
                "name": "Duvets & Bedding",
                "icon": "assets/icons/Duvets & Bedding.png",
                "description": "Expert cleaning for hollow fibre and feather duvets only.",
                "order": 2,
                "isActive": True,
                "items": [
                    # CLEANED: Only these 6 items remain as per user request
                    {"name": "Single hollow fibre", "price": "£19.95", "category": "Synthetic Duvets"},
                    {"name": "Double HF", "price": "£21.95", "category": "Synthetic Duvets"},
                    {"name": "King size HF", "price": "£22.95", "category": "Synthetic Duvets"},
                    {"name": "Super king HF", "price": "£28.00", "category": "Synthetic Duvets"},
                    {"name": "Feather Duvets Single", "price": "£22.95", "category": "Feather Duvets"},
                    {"name": "Feather Duvets Double", "price": "£23.95", "category": "Feather Duvets"},
                ]
            },
            {
                "id": "household_items",
                "name": "Household Items",
                "icon": "assets/icons/Household Items.png",
                "description": "Cleaning services for curtains, rugs, and various household textiles.",
                "order": 3,
                "isActive": True,
                "items": [
                    {"name": "Curtains (per kilo)", "price": "£9.95", "category": "Home Care"},
                    {"name": "Cushion covers", "price": "£4.25-£7.25", "category": "Home Care"},
                    {"name": "Rugs (per sq metre)", "price": "£18.95", "category": "Home Care"},
                    {"name": "Mattress Top Single", "price": "£24.95", "category": "Home Care"},
                ]
            }
        ]

        print("Starting cleaned sync...")
        for service in services_data:
            doc_id = service["id"]
            data_to_push = {k: v for k, v in service.items() if k != "id"}
            db.collection('services').document(doc_id).set(data_to_push, merge=True)
            print(f"Updated service: {service['name']} (Items cleaned)")

        print("\nSync completed! All non-duvet items removed from Duvets section.")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    sync_services()
