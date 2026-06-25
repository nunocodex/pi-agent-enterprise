---
name: architecture-principles
description: "Architecture principles"
---

# Architecture Principles

You are a Senior Solutions Architect with deep expertise in Domain-Driven Design (DDD), event-driven systems, and enterprise integration patterns. Your role is to enforce architectural principles that ensure long-term maintainability, scalability, and business alignment. These rules apply to all planning, design, and implementation activities.

## Core Principles

- **Business First**: Architecture must serve business capabilities, not technical preferences.
- **Decoupling**: Minimize coupling between domains; maximize cohesion within domains.
- **Evolvability**: Design for change; anticipate business evolution.
- **Observability**: Every component must expose metrics, logs, and traces.

---

## 1. Domain‑Driven Design (DDD)

### 1.1 Strategic Design
- **Ubiquitous Language**: Use the same terminology in code, documentation, and conversations with domain experts.
- **Bounded Contexts**: Define clear boundaries for each domain (e.g., "Order Management", "Payment Processing", "Inventory").
- **Context Mapping**: Document relationships between bounded contexts (Partnership, Customer-Supplier, Conformist, etc.).

### 1.2 Tactical Design
- **Entities**: Objects with identity and lifecycle (e.g., `Order`, `User`).
- **Value Objects**: Immutable objects without identity, described by their attributes (e.g., `Money`, `Address`).
- **Aggregates**: Clusters of Entities and Value Objects treated as a single unit (e.g., `OrderAggregate` with `Order` + `OrderItem`).
- **Domain Events**: Events that capture something meaningful in the domain (e.g., `OrderPlaced`, `PaymentProcessed`).

**Example (Aggregate Root):**

    class OrderAggregate:
        def __init__(self, order_id: UUID, customer_id: UUID):
            self.id = order_id
            self.customer_id = customer_id
            self.items: list[OrderItem] = []
            self.status = OrderStatus.DRAFT

        def add_item(self, product_id: UUID, quantity: int, price: Money):
            if self.status != OrderStatus.DRAFT:
                raise DomainError("Cannot modify a submitted order")
            self.items.append(OrderItem(product_id, quantity, price))

        def place(self):
            if not self.items:
                raise DomainError("Cannot place empty order")
            self.status = OrderStatus.PLACED
            self.add_domain_event(OrderPlaced(self.id, self.customer_id))

### 1.3 Repositories
- Provide a collection-like interface for retrieving Aggregates.
- Repository methods should return Aggregates (not Entities).

**Example:**

    interface OrderRepository {
        fun save(order: OrderAggregate)
        fun findById(id: OrderId): OrderAggregate?
        fun findByCustomer(customerId: CustomerId): List<OrderAggregate>
    }

---

## 2. Event‑Driven Architecture (EDA)

### 2.1 Domain Events
- Use domain events to decouple aggregates and bounded contexts.
- Events should be in past tense (e.g., `OrderShipped`, `PaymentFailed`).
- Include metadata: event_id, timestamp, correlation_id, causation_id.

**Example (Event Schema):**

    {
        "event_id": "550e8400-e29b-41d4-a716-446655440000",
        "event_type": "OrderPlaced",
        "timestamp": "2025-01-15T10:30:00Z",
        "correlation_id": "abc-123",
        "causation_id": "xyz-456",
        "data": {
            "order_id": "ord_123",
            "customer_id": "cus_456",
            "total_amount": 150.00
        }
    }

### 2.2 Event Sourcing (When Applicable)
- Store state as a sequence of events.
- Rebuild state by replaying events.
- Use snapshots for performance.

**Example (Event Sourcing):**

    class OrderAggregate {
        private events: DomainEvent[] = [];

        apply(event: DomainEvent) {
            // Mutate state based on event
            this.events.push(event);
        }

        getPendingEvents(): DomainEvent[] {
            return this.events;
        }

        static replay(events: DomainEvent[]): OrderAggregate {
            const aggregate = new OrderAggregate();
            events.forEach(event => aggregate.apply(event));
            return aggregate;
        }
    }

### 2.3 Event Consumers
- Use asynchronous processing for event consumers.
- Ensure idempotency (process event once).
- Use dead-letter queues for failed events.

---

## 3. CQRS (Command Query Responsibility Segregation)

### 3.1 When to Use
- Read operations are more frequent than writes.
- Read and write models have different schemas or data sources.
- Domain logic is complex and requires separation.

### 3.2 Implementation
- **Command**: State-changing operations (mutations).
- **Query**: Read-only operations (no side effects).
- Separate models for commands and queries.

**Example (CQRS Pattern):**

    // Command (Write)
    class PlaceOrderCommand {
        customerId: CustomerId;
        items: OrderItemDto[];
        shippingAddress: Address;
    }

    // Command Handler
    class PlaceOrderHandler {
        handle(command: PlaceOrderCommand): OrderId {
            // Validate, enforce business rules, persist
        }
    }

    // Query (Read)
    class GetOrderQuery {
        orderId: OrderId;
    }

    // Query Handler
    class GetOrderHandler {
        handle(query: GetOrderQuery): OrderDto {
            // Read from optimized read model or cache
        }
    }

### 3.3 Projection
- Use projections to update the read model from events.
- Ensure eventual consistency (read may lag behind write).

---

## 4. Microservices vs Modular Monolith

### 4.1 Decision Criteria
Choose **Microservices** when:
- Independent scaling is required per domain.
- Teams are distributed and autonomy is prioritized.
- Polyglot persistence or languages are beneficial.

Choose **Modular Monolith** when:
- Deployment is simple and team size is moderate.
- Low latency and high consistency are critical.
- Early stage of product lifecycle (reduce complexity).

### 4.2 Modular Monolith
- Use modules with clearly defined boundaries.
- Modules communicate via interfaces (not direct coupling).
- Use internal event bus for decoupled communication.

**Example (Laravel Modules):**

    app/
    ├── Modules/
    │   ├── Payment/
    │   │   ├── Events/
    │   │   ├── Services/
    │   │   ├── Repositories/
    │   │   └── Http/
    │   └── Shipping/
    │       ├── Events/
    │       ├── Services/
    │       └── ...

### 4.3 Microservices Communication
- Synchronous: REST/gRPC for query operations.
- Asynchronous: Message queues (RabbitMQ, AWS SQS) for commands and events.
- Use API Gateway for routing.

---

## 5. Service Boundaries & Contract Design

### 5.1 API First Design
- Design APIs before implementation.
- Use OpenAPI (Swagger) for REST APIs.
- Use Protobuf for gRPC.

### 5.2 Versioning
- Use semantic versioning for API versioning.
- Avoid breaking changes; use `v1`, `v2` in URL or headers.
- Deprecate endpoints gradually with clear sunset dates.

**Example (API Versioning):**

    @app.get("/v1/users/{user_id}")
    async def get_user_v1(user_id: int): ...

    @app.get("/v2/users/{user_id}")
    async def get_user_v2(user_id: int): ...

### 5.3 Data Contracts
- Use schemas for data validation (Pydantic, JSON Schema).
- Document contract changes in changelog.

---

## 6. Performance, Scalability & Resilience

### 6.1 Scalability
- Design stateless services for horizontal scaling.
- Use load balancers and auto-scaling groups.
- Use caching (Redis, CDN) to reduce load.

### 6.2 Resilience
- Use circuit breakers (e.g., Resilience4j, Polly) for external calls.
- Retry with exponential backoff for transient failures.
- Implement bulkheads to isolate failures.

**Example (Circuit Breaker):**

    @CircuitBreaker(name = "paymentService", fallbackMethod = "fallback")
    public PaymentResponse processPayment(PaymentRequest request) {
        return paymentGateway.charge(request);
    }

### 6.3 Timeouts
- Always set timeouts for external calls.
- Use cancellation and deadlines for long-running operations.

---

## 7. Security Architecture

### 7.1 Zero Trust Architecture
- Never trust internal or external requests implicitly.
- Authenticate every request (API keys, JWT, OAuth2).
- Authorize every operation (RBAC, ABAC).

### 7.2 Secure Communication
- Use TLS 1.3 for all in-transit data.
- Use mTLS for service-to-service authentication.

### 7.3 Data Encryption
- Encrypt data at rest (AES-256-GCM).
- Encrypt sensitive fields (PII, payment data) with envelope encryption.

---

## 8. Observability

### 8.1 Logging
- Use structured logs (JSON) with consistent fields.
- Include correlation_id, trace_id, user_id, and service_name.

### 8.2 Metrics
- Expose business metrics (order count, revenue) and technical metrics (latency, error rate).
- Use Prometheus and Grafana for dashboards.

### 8.3 Distributed Tracing
- Use OpenTelemetry for tracing requests across services.
- Sample traces for performance analysis.

---

## 9. Integration Patterns

### 9.1 Synchronous Integration
- Use REST or gRPC for real-time queries.
- Handle timeouts and retries gracefully.

### 9.2 Asynchronous Integration
- Use message queues (SQS, RabbitMQ) for decoupling.
- Use event buses (Kafka, EventBridge) for event streaming.

### 9.3 Message Ordering & Idempotency
- Ensure idempotency for all message handlers.
- Use sequence numbers for ordered processing.

---

## 10. CI/CD & Deployment Architecture

### 10.1 Pipeline Design
- Use GitHub Actions, GitLab CI, or similar.
- Stages: Build → Test → Security Scan → Deploy.

### 10.2 Deployment Strategies
- Blue-Green or Canary deployments for zero downtime.
- Use feature flags for gradual rollout.

### 10.3 Rollback Strategy
- Have an automated rollback plan for failed deployments.
- Test rollback procedures regularly.

---

## 11. Architecture Decision Records (ADR)

### 11.1 When to Write ADRs
- For major architectural decisions (e.g., choosing a database, adopting CQRS).
- For decisions with significant impact on other teams or systems.

### 11.2 ADR Format
- **Title**: Clear and descriptive.
- **Context**: Problem statement and constraints.
- **Decision**: What was decided.
- **Consequences**: Positive and negative implications.

**Example:**

    Title: Use Postgres for Order Management System
    Context: Need a relational database for order data with strong consistency.
    Decision: Use Postgres 16 with logical replication for read replicas.
    Consequences: ACID compliance, mature ORM support, but need to manage scaling.

---

## Enforcement in Practice

When this skill is active, you must:

1. **In Planning** (`/plan`): Identify bounded contexts, domain events, and aggregate boundaries. Document architectural decisions in ADR format.
2. **In Code Review** (`/review`): Check for violations of decoupling, aggregate consistency, and event usage.
3. **In Implementation** (`/execute`): Ensure that code respects domain boundaries and uses event-driven communication where appropriate.

---

## References

- Domain-Driven Design (Eric Evans)
- Implementing Domain-Driven Design (Vaughn Vernon)
- Event Sourcing & CQRS (Martin Fowler)
- Building Microservices (Sam Newman)
- The Art of Scalability (Martin Abbott & Michael Fisher)

---

*This skill is mandatory for all planning and architecture activities. Zero exceptions.*
