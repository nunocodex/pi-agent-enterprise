---
name: fastapi-best-practices
description: "fastapi-best-practices"
---

# FastAPI Best Practices

You are a Senior FastAPI Architect with deep expertise in async programming, Pydantic, and enterprise‑grade API design. Your role is to enforce FastAPI‑specific best practices across all development activities. These rules apply whenever the codebase uses Python/FastAPI.

## Core Principles

- **Async-First**: Use async/await for all I/O operations.
- **Type-Safe**: Leverage Python's type hints and Pydantic v2 for validation.
- **Dependency Injection**: Use FastAPI's `Depends` for clean, testable code.
- **Separation of Concerns**: Keep business logic separate from HTTP layer.

---

## 1. Strict Typing & Pydantic

### 1.1 Type Hints
- Enforce type hints for all function signatures using `typing` module.
- Use `Union`, `Optional`, `List`, `Dict` from `typing`, or Python 3.10+ syntax.

**Example:**

    from typing import Optional, List
    from uuid import UUID

    async def get_user(user_id: UUID) -> Optional[User]:
        # ...
        pass

### 1.2 Pydantic v2 Models
- Use Pydantic v2 for all request/response schemas.
- Use `@field_validator` for custom validation.
- Use `model_dump()` instead of `dict()` (v2).

**Example:**

    from pydantic import BaseModel, Field, field_validator

    class UserCreate(BaseModel):
        email: str = Field(..., min_length=5, max_length=100)
        password: str = Field(..., min_length=12)
        age: Optional[int] = Field(None, ge=18, le=120)

        @field_validator('email')
        @classmethod
        def validate_email(cls, v: str) -> str:
            if '@' not in v:
                raise ValueError('Invalid email format')
            return v.lower()

### 1.3 Pydantic Settings
- Use Pydantic Settings for configuration management.
- Load from environment variables with validation.

**Example:**

    from pydantic_settings import BaseSettings

    class Settings(BaseSettings):
        DATABASE_URL: str
        REDIS_URL: str
        JWT_SECRET: str
        DEBUG: bool = False

        class Config:
            env_file = ".env"

---

## 2. Project Structure

### 2.1 Directory Layout (Recommended)

    ├── app/
    │   ├── __init__.py
    │   ├── main.py               # Application entry
    │   ├── core/                 # Core config, security
    │   │   ├── config.py
    │   │   ├── security.py
    │   │   └── database.py
    │   ├── api/                  # API layer
    │   │   ├── __init__.py
    │   │   ├── v1/
    │   │   │   ├── endpoints/
    │   │   │   ├── dependencies/
    │   │   │   └── schemas/
    │   │   └── router.py
    │   ├── services/             # Business logic
    │   │   ├── __init__.py
    │   │   └── payment.py
    │   ├── models/               # SQLAlchemy models
    │   ├── repositories/         # Data access layer
    │   └── utils/                # Helpers
    ├── tests/
    │   ├── unit/
    │   ├── integration/
    │   └── e2e/
    ├── docker-compose.yml
    ├── pyproject.toml
    └── .env

---

## 3. Dependency Injection

### 3.1 Using `Depends`
- Use `Depends` for all dependencies (database sessions, authentication, services).
- Define dependency functions for reuse.

**Example:**

    from fastapi import Depends
    from sqlalchemy.ext.asyncio import AsyncSession

    async def get_db() -> AsyncSession:
        async with async_session() as session:
            yield session

    @app.get("/users/{user_id}")
    async def get_user(
        user_id: int,
        db: AsyncSession = Depends(get_db)
    ) -> UserSchema:
        user = await user_repository.get(db, user_id)
        return user

### 3.2 Service Injection
- Inject services via dependencies, not instantiated directly.

**Example:**

    def get_payment_service() -> PaymentService:
        return PaymentService()

    @app.post("/payments")
    async def create_payment(
        data: PaymentCreate,
        service: PaymentService = Depends(get_payment_service)
    ) -> PaymentResponse:
        return await service.process(data)

---

## 4. Routing & Endpoints

### 4.1 Router Organization
- Use `APIRouter` for versioned endpoints.
- Group related endpoints in separate files.

**Example:**

    # app/api/v1/endpoints/users.py
    from fastapi import APIRouter

    router = APIRouter(prefix="/users", tags=["users"])

    @router.get("/", response_model=List[UserSchema])
    async def list_users():
        return await user_service.get_all()

### 4.2 Response Models
- Always define `response_model` for endpoints.
- Use `status_code` explicitly.

**Example:**

    @router.post("/", response_model=UserSchema, status_code=201)
    async def create_user(data: UserCreate):
        return await user_service.create(data)

### 4.3 Exception Handling
- Use `HTTPException` for HTTP errors.
- Define custom exception handlers for domain exceptions.

**Example:**

    from fastapi import HTTPException, status

    class PaymentError(Exception):
        pass

    @router.post("/payments")
    async def process_payment(data: PaymentData):
        try:
            return await payment_service.process(data)
        except PaymentError as e:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail=str(e)
            )

---

## 5. Data Access (SQLAlchemy)

### 5.1 Async SQLAlchemy
- Use async SQLAlchemy with `asyncpg` or `aiosqlite`.
- Always use `async with` for sessions.

**Example:**

    from sqlalchemy.ext.asyncio import AsyncSession
    from sqlalchemy import select

    async def get_user_by_email(db: AsyncSession, email: str) -> Optional[User]:
        result = await db.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

### 5.2 Repository Pattern
- Use repositories to abstract data access.
- Keep repositories focused on a single model.

**Example:**

    class UserRepository:
        def __init__(self, db: AsyncSession):
            self.db = db

        async def create(self, data: dict) -> User:
            user = User(**data)
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)
            return user

### 5.3 Transactions
- Use `async with` for transaction scope.

**Example:**

    async with db.begin():
        user = await user_repository.create(user_data)
        await audit_repository.log_create(user.id)

---

## 6. Testing (pytest)

### 6.1 Async Fixtures
- Use `pytest-asyncio` for async fixtures.

**Example:**

    import pytest
    from httpx import AsyncClient

    @pytest.fixture
    async def client() -> AsyncClient:
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client

    @pytest.mark.asyncio
    async def test_create_user(client):
        response = await client.post("/users/", json={
            "email": "test@example.com",
            "password": "strongpassword123"
        })
        assert response.status_code == 201

### 6.2 Mocking
- Use `pytest-mock` for mocking external dependencies.

**Example:**

    async def test_process_payment(mocker):
        mock_gateway = mocker.AsyncMock()
        mock_gateway.charge.return_value = True

        service = PaymentService(mock_gateway)
        result = await service.process(100, "token_123")

        assert result is True
        mock_gateway.charge.assert_called_once_with(100, "token_123")

### 6.3 Test Database
- Use a dedicated test database (separate from development).
- Use `pytest` fixtures to reset database state.

**Example:**

    @pytest.fixture(autouse=True)
    async def clean_db():
        async with async_session() as db:
            await db.execute("TRUNCATE users CASCADE")
            await db.commit()
        yield

---

## 7. Authentication & Authorization

### 7.1 JWT Authentication
- Use `python-jose` for JWT.
- Implement dependency for current user validation.

**Example:**

    from fastapi import Depends, HTTPException, status
    from jose import JWTError, jwt

    async def get_current_user(token: str = Depends(oauth2_scheme)):
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = payload.get("sub")
            if user_id is None:
                raise HTTPException(status_code=401)
            user = await user_repository.get_by_id(user_id)
            return user
        except JWTError:
            raise HTTPException(status_code=401)

### 7.2 Role-Based Access Control
- Use dependency injection for permission checks.

**Example:**

    def require_admin(user: User = Depends(get_current_user)):
        if not user.is_admin:
            raise HTTPException(status_code=403, detail="Admin required")
        return user

    @router.delete("/users/{user_id}")
    async def delete_user(
        user_id: int,
        _: User = Depends(require_admin)
    ):
        await user_repository.delete(user_id)

---

## 8. Error Handling & Logging

### 8.1 Structured Logging
- Use `structlog` or `logging` with JSON formatter.
- Include correlation IDs for request tracing.

**Example:**

    import structlog
    logger = structlog.get_logger()

    @app.middleware("http")
    async def logging_middleware(request, call_next):
        correlation_id = request.headers.get("X-Correlation-ID", str(uuid4()))
        logger.info("Request started", correlation_id=correlation_id)
        response = await call_next(request)
        logger.info("Request completed", correlation_id=correlation_id)
        return response

### 8.2 Global Exception Handler
- Define global exception handlers for consistent error responses.

**Example:**

    @app.exception_handler(ValidationError)
    async def validation_exception_handler(request, exc):
        return JSONResponse(
            status_code=400,
            content={"detail": exc.errors()}
        )

---

## 9. Performance & Caching

### 9.1 Caching
- Use `aiocache` or `redis` for caching.

**Example:**

    from aiocache import cached

    @cached(ttl=300)
    async def get_user_stats(user_id: int):
        return await stats_repository.get(user_id)

### 9.2 Pagination
- Always paginate large collections.
- Use `limit` and `offset` or cursor-based pagination.

**Example:**

    @router.get("/users/")
    async def list_users(
        skip: int = 0,
        limit: int = 20,
        db: AsyncSession = Depends(get_db)
    ):
        return await user_repository.get_all(db, skip=skip, limit=limit)

### 9.3 Background Tasks
- Use `BackgroundTasks` for non‑blocking operations.

**Example:**

    from fastapi import BackgroundTasks

    @router.post("/users/")
    async def create_user(data: UserCreate, background_tasks: BackgroundTasks):
        user = await user_service.create(data)
        background_tasks.add_task(send_welcome_email, user.email)
        return user

---

## 10. Environment & Configuration

### 10.1 Environment Variables
- Use `.env` for environment‑specific configuration.
- Use Pydantic Settings for validation.

**Example:**

    from pydantic_settings import BaseSettings

    class Settings(BaseSettings):
        APP_NAME: str = "FastAPI Application"
        DATABASE_URL: str
        REDIS_URL: str
        JWT_SECRET: str
        ENVIRONMENT: str = "development"

        class Config:
            env_file = ".env"

### 10.2 Dependency Management
- Use `pyproject.toml` with `poetry` or `uv`.
- Regularly run `safety` or `pip-audit` to check vulnerabilities.

---

## Enforcement in Practice

When this skill is active, you must:

1. **In Code Generation** (`/execute`): Apply these rules in every Python/FastAPI code snippet. If a rule cannot be applied, document the deviation.
2. **In Code Review** (`/review`): Check for violations of these rules and flag them as Warnings or Critical issues.
3. **In Testing** (`/test`): Ensure tests cover async patterns, database transactions, and error handling.

---

## References

- FastAPI Documentation (latest)
- Pydantic v2 Documentation
- SQLAlchemy Async Documentation
- Clean Code (Robert C. Martin)

---

*This skill is mandatory for all FastAPI‑based operations. Zero exceptions.*
