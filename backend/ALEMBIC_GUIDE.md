# Alembic Migration Commands

## Initialize Alembic (already done)
```bash
alembic init alembic
```

## Create automatic migration
```bash
# Make sure .env file exists with DATABASE_URL
alembic revision --autogenerate -m "Add authority_score and encrypted_shares"
```

## Apply migrations
```bash
# Upgrade to latest
alembic upgrade head

# Downgrade one version
alembic downgrade -1

# Show current version
alembic current

# Show migration history
alembic history
```

## Seed demo data
```bash
python scripts/seed_demo_data.py
```

## Notes
- Alembic will automatically detect model changes
- Make sure all models are imported in `alembic/env.py`
- Database URL is loaded from settings (`.env` file)
