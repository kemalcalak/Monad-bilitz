import asyncio
import logging
from sqlalchemy import select

import bcrypt

from app.db.session import async_session_factory
from app.models.hierarchy import Group, OrganizationUnit
from app.models.user import User
from app.models.contract import Contract
from app.models.signature import ApprovalRequest, Signature # Ensure Contract is registered for relationships

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Password hashing
def hash_password(password: str) -> str:
    pwd_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pwd_bytes, salt)
    return hashed.decode('utf-8')

async def seed_data():
    async with async_session_factory() as session:
        logger.info("Seeding data...")

        # 1. Groups
        groups_data = [
            {"group_name": "CEO", "display_name": "Chief Executive Officer", "authority_score": 100, "level": 1},
            {"group_name": "CFO", "display_name": "Chief Financial Officer", "authority_score": 80, "level": 2},
            {"group_name": "CTO", "display_name": "Chief Technology Officer", "authority_score": 80, "level": 2},
            {"group_name": "DEPT_HEAD", "display_name": "Department Head", "authority_score": 50, "level": 3},
            {"group_name": "MANAGER", "display_name": "Manager", "authority_score": 30, "level": 4},
            {"group_name": "EMPLOYEE", "display_name": "Employee", "authority_score": 10, "level": 5},
        ]

        for g_data in groups_data:
            result = await session.execute(select(Group).where(Group.group_name == g_data["group_name"]))
            if not result.scalar_one_or_none():
                group = Group(**g_data)
                session.add(group)
        
        await session.flush() # ID'lerin oluşması için

        # 2. Organization Unit (Root)
        result = await session.execute(select(OrganizationUnit).where(OrganizationUnit.name == "Headquarters"))
        ou = result.scalar_one_or_none()
        if not ou:
            ou = OrganizationUnit(
                name="Headquarters", 
                prime_field_hex="0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F" # Secp256k1 order
            )
            session.add(ou)
            await session.flush()

        # 3. Users
        users_data = [
            {"username": "ceo_user", "email": "ceo@example.com", "target_group": "CEO"},
            {"username": "cfo_user", "email": "cfo@example.com", "target_group": "CFO"},
            {"username": "cto_user", "email": "cto@example.com", "target_group": "CTO"},
            {"username": "manager_user", "email": "manager@example.com", "target_group": "MANAGER"},
        ]

        # Get groups to link
        # We need to query them back or track them
        
        for u_data in users_data:
            result = await session.execute(select(User).where(User.username == u_data["username"]))
            if not result.scalar_one_or_none():
                # Find the group
                grp_result = await session.execute(select(Group).where(Group.group_name == u_data["target_group"]))
                grp = grp_result.scalar_one()
                
                user = User(
                    username=u_data["username"],
                    email=u_data["email"],
                    hashed_password=hash_password("password123"),
                    group_id=grp.id
                )
                session.add(user)

        await session.commit()
        logger.info("Data seeded successfully!")

if __name__ == "__main__":
    asyncio.run(seed_data())
