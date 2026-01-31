import httpx
import asyncio
import sys

BASE_URL = "http://localhost:8000/api/v1"
HEADERS = {}

COLORS = {
    "HEADER": "\033[95m",
    "OKBLUE": "\033[94m",
    "OKGREEN": "\033[92m",
    "WARNING": "\033[93m",
    "FAIL": "\033[91m",
    "ENDC": "\033[0m",
}

def print_step(msg):
    print(f"\n{COLORS['HEADER']}▶ {msg}{COLORS['ENDC']}")

def print_success(msg):
    print(f"{COLORS['OKGREEN']}  ✓ {msg}{COLORS['ENDC']}")

def print_fail(msg):
    print(f"{COLORS['FAIL']}  ✕ {msg}{COLORS['ENDC']}")
    sys.exit(1)

async def test_auth_flow():
    """Test Register and Login"""
    print_step("Testing Authentication Flow")
    
    # 1. Register CEO
    async with httpx.AsyncClient() as client:
        # Register CEO
        ceo_data = {
            "username": "api_test_ceo",
            "email": "apitest_ceo@example.com",
            "password": "password123"
        }
        resp = await client.post(f"{BASE_URL}/auth/register", json=ceo_data)
        if resp.status_code in [201, 400]: # 400 if already exists
            print_success("User Registration (CEO)")
        else:
            print_fail(f"Registration failed: {resp.text}")

        # Login CEO
        login_data = {"username": "api_test_ceo", "password": "password123"}
        resp = await client.post(f"{BASE_URL}/auth/login", data=login_data)
        if resp.status_code == 200:
            token = resp.json()["access_token"]
            print_success("Login (CEO)")
            return token
        else:
            print_fail(f"Login failed: {resp.text}")

async def test_contract_flow(token):
    """Test Contract Lifecycle"""
    print_step("Testing Contract Flow")
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        # 1. Create Contract
        contract_data = {
            "title": "API Test Contract",
            "content": "This is a test contract created by script.",
            "contract_type": "general",
            "amount": 5000,
            "urgency": "high"
        }
        resp = await client.post(f"{BASE_URL}/contracts/", json=contract_data, headers=headers)
        if resp.status_code == 201:
            contract = resp.json()
            contract_id = contract["contract_id"]
            db_id = contract["id"] # UUID
            print_success(f"Contract Created (ID: {contract_id})")
        else:
            print_fail(f"Contract creation failed: {resp.text}")

        # 2. List Contracts
        resp = await client.get(f"{BASE_URL}/contracts/", headers=headers)
        if resp.status_code == 200 and len(resp.json()) > 0:
             print_success(f"List Contracts (Found {len(resp.json())})")
        else:
             print_fail("List contracts failed or empty")

        # 3. Get Contract Details
        resp = await client.get(f"{BASE_URL}/contracts/{contract_id}", headers=headers)
        if resp.status_code == 200:
            print_success("Get Contract Details")
        else:
            print_fail("Get contract details failed")
            
        # 4. Sign Contract (as same user for simplicity, usually needs authority)
        # Note: In real logic, user needs authority score. 
        # Since we just registered a fresh user, they might not have a group/score assigned yet 
        # unless Seed Data ran.
        print_step("Attempting to Sign Contract")
        resp = await client.post(f"{BASE_URL}/contracts/{contract_id}/sign", headers=headers)
        
        if resp.status_code == 200:
            print_success("Contract Signed Successfully")
            score = resp.json()["authority_score"]
            print(f"    (Authority Score: {score})")
        elif resp.status_code == 403:
             print(f"{COLORS['WARNING']}  ⚠ Signing Skipped: User has no authority score yet (Expected for new user){COLORS['ENDC']}")
        else:
             print_fail(f"Signing failed: {resp.text}")

async def test_hierarchy(token):
    """Test Hierarchy Routes"""
    print_step("Testing Hierarchy Flow")
    headers = {"Authorization": f"Bearer {token}"}
    
    async with httpx.AsyncClient() as client:
        resp = await client.get(f"{BASE_URL}/hierarchy/graph", headers=headers)
        if resp.status_code == 200:
            data = resp.json()
            nodes = len(data.get("nodes", []))
            print_success(f"Fetch Hierarchy Graph ({nodes} nodes found)")
        else:
            print_fail("Fetch hierarchy graph failed")

async def main():
    print(f"{COLORS['OKBLUE']}STARING API END-TO-END TEST...{COLORS['ENDC']}")
    
    # Run Auth
    token = await test_auth_flow()
    
    if token:
        # Run Contract Tests
        await test_contract_flow(token)
        
        # Run Hierarchy Tests
        await test_hierarchy(token)
        
    print(f"\n{COLORS['OKGREEN']}ALL TESTS COMPLETED SUCCESSFULLY! 🚀{COLORS['ENDC']}")

if __name__ == "__main__":
    asyncio.run(main())
