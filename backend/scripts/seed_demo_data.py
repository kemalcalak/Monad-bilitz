"""
Seed demo data for testing

Creates:
- 6 demo groups (CEO, CFO, CTO, DEPT_HEAD, MANAGER, EMPLOYEE)
- 6 demo users (one for each group)
- Sample contracts
"""

import asyncio
import uuid
from datetime import datetime

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from passlib.context import CryptContext

from app.config import settings
from app.models.user import User
from app.models.hierarchy import Group
from app.models.contract import Contract
from app.db.base import Base


# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def seed_data():
    """Seed demo data"""
    # Create async engine
    engine = create_async_engine(settings.DATABASE_URL, echo=True)
    
    # Create session
    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )
    
    async with async_session() as session:
        print("🌱 Seeding demo data...")
        
        # Create groups
        groups_data = [
            {"group_name": "CEO", "display_name": "Chief Executive Officer", "level": 1, "authority_score": 100},
            {"group_name": "CFO", "display_name": "Chief Financial Officer", "level": 2, "authority_score": 80},
            {"group_name": "CTO", "display_name": "Chief Technology Officer", "level": 2, "authority_score": 80},
            {"group_name": "DEPT_HEAD", "display_name": "Department Head", "level": 3, "authority_score": 50},
            {"group_name": "MANAGER", "display_name": "Manager", "level": 4, "authority_score": 30},
            {"group_name": "EMPLOYEE", "display_name": "Employee", "level": 5, "authority_score": 10},
        ]
        
        groups = {}
        for group_data in groups_data:
            group = Group(**group_data)
            session.add(group)
            groups[group_data["group_name"]] = group
            print(f"  ✓ Created group: {group_data['display_name']} (score: {group_data['authority_score']})")
        
        await session.commit()
        
        # Create users
        users_data = [
            {"username": "ceo_user", "email": "ceo@example.com", "password": "password123", "group": "CEO", "wallet": "0xCEO1234567890abcdef"},
            {"username": "cfo_user", "email": "cfo@example.com", "password": "password123", "group": "CFO", "wallet": "0xCFO1234567890abcdef"},
            {"username": "cto_user", "email": "cto@example.com", "password": "password123", "group": "CTO", "wallet": "0xCTO1234567890abcdef"},
            {"username": "dept_user", "email": "dept@example.com", "password": "password123", "group": "DEPT_HEAD", "wallet": "0xDEPT234567890abcdef"},
            {"username": "manager_user", "email": "manager@example.com", "password": "password123", "group": "MANAGER", "wallet": "0xMGR1234567890abcdef"},
            {"username": "employee_user", "email": "employee@example.com", "password": "password123", "group": "EMPLOYEE", "wallet": "0xEMP1234567890abcdef"},
        ]
        
        users = {}
        for user_data in users_data:
            user = User(
                username=user_data["username"],
                email=user_data["email"],
                hashed_password=pwd_context.hash(user_data["password"]),
                wallet_address=user_data["wallet"],
                group_id=groups[user_data["group"]].id
            )
            session.add(user)
            users[user_data["username"]] = user
            print(f"  ✓ Created user: {user_data['username']} ({user_data['group']})")
        
        await session.commit()
        
        # Create sample contracts
        contracts_data = [
            {
                "contract_id": "CONTRACT_DEMO_001",
                "title": "Office Supplies Purchase",
                "content": "Purchase of office supplies for Q1 2024",
                "contract_type": "general",
                "amount": 5000.00,
                "required_score": 50,
                "creator": "employee_user"
            },
            {
                "contract_id": "CONTRACT_DEMO_002",
                "title": "Software License Renewal",
                "content": "Annual renewal of enterprise software licenses",
                "contract_type": "financial",
                "amount": 25000.00,
                "required_score": 100,
                "creator": "manager_user"
            },
            {
                "contract_id": "CONTRACT_DEMO_003",
                "title": "Partnership Agreement",
                "content": "Legal partnership agreement with XYZ Corp",
                "contract_type": "legal",
                "amount": 50000.00,
                "required_score": 180,
                "creator": "cfo_user"
            },
        ]
        
        for contract_data in contracts_data:
            creator_username = contract_data.pop("creator")
            contract = Contract(
                **contract_data,
                creator_id=users[creator_username].id,
                current_score=0,
                status="pending"
            )
            session.add(contract)
            print(f"  ✓ Created contract: {contract_data['title']}")
        
        await session.commit()
        
        print("\n✅ Demo data seeded successfully!")
        print("\n📝 Demo Users:")
        print("  Username: ceo_user | Password: password123 | Group: CEO (score: 100)")
        print("  Username: cfo_user | Password: password123 | Group: CFO (score: 80)")
        print("  Username: cto_user | Password: password123 | Group: CTO (score: 80)")
        print("  Username: dept_user | Password: password123 | Group: DEPT_HEAD (score: 50)")
        print("  Username: manager_user | Password: password123 | Group: MANAGER (score: 30)")
        print("  Username: employee_user | Password: password123 | Group: EMPLOYEE (score: 10)")


if __name__ == "__main__":
    asyncio.run(seed_data())
