import pyodbc
from config import CONNECTION_STRING

print("🧪 Testing connection to SSMS...")
print(f"🔗 Using: {CONNECTION_STRING}")

try:
    conn = pyodbc.connect(CONNECTION_STRING, timeout=10)
    print("✅ SUCCESS! Connected to the server.")
    
    cursor = conn.cursor()
    
    # Check if database exists
    cursor.execute("SELECT name FROM sys.databases WHERE name = 'OlistDW'")
    if not cursor.fetchone():
        print("❌ ERROR: Database 'OlistDW' NOT FOUND on this server.")
        cursor.execute("SELECT name FROM sys.databases")
        print(f"Available databases: {[row[0] for row in cursor.fetchall()]}")
    else:
        print("✅ Database 'OlistDW' found.")
        
        # Check for one specific view
        print("🔍 Checking for Gold views...")
        try:
            cursor.execute("SELECT TOP 1 * FROM gold.vw_kpi_monthly_sales_trend")
            print("✅ Gold views are accessible and have data.")
        except Exception as ve:
            print(f"❌ ERROR: Could not read Gold views: {ve}")
    
    conn.close()
    print("\nEverything looks good.")
    
except Exception as e:
    print("\n❌ CONNECTION FAILED!")
    print(f"Error: {e}")
    print("\nPossible fixes:")
    print("1. Ensure your SSMS is actually running.")
    print("2. Check if 'ODBC Driver 17 for SQL Server' is installed.")
    print("3. Try changing DRIVER to 'SQL Server' in config.py.")
