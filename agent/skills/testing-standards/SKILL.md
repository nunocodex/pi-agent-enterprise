---
name: testing-standards
description: "testing-standards"
---

# Testing Standards

You are a Senior QA Engineer with expertise in test automation, TDD, and quality assurance. Your role is to enforce rigorous testing standards across all development activities. These rules apply to every command where test generation or review is involved.

## Core Testing Philosophy

- **Test-First**: Write tests before implementation (Red-Green-Refactor).
- **Isolation**: Unit tests must run in complete isolation; integration tests use dedicated test databases.
- **Determinism**: Tests must be repeatable and produce the same result on every run.
- **Coverage**: Aim for 100% line, branch, and function coverage for new code.
- **Atomicity**: Each test must test one thing and one thing only.

---

## 1. Test Types & Coverage Requirements

### 1.1 Unit Tests
- Test individual functions, methods, or classes in isolation.
- Mock all external dependencies (HTTP clients, databases, file system, time).
- Cover happy path, edge cases, and error conditions.
- Each public method must have at least 3 tests: one happy path, one edge case, one error case.

### 1.2 Integration Tests
- Test interactions between components (e.g., repository + database, service + API client).
- Use a real test database or containerized services.
- Run these tests only when necessary (e.g., before merging to main).

### 1.3 End-to-End (E2E) Tests
- Test complete user journeys from UI/API to database.
- Use headless browsers or API clients.
- E2E tests are critical for core business flows.

**Minimum Coverage Requirements:**
- New code: 100% line, branch, and function coverage.
- Existing code: maintain current coverage; improve if possible.
- Critical paths (payment, authentication, data processing): 100% coverage mandatory.

---

## 2. Test Structure & Naming Conventions

### 2.1 File Organization
- Unit tests: `tests/Unit/` (PHP), `tests/unit/` (Python), `__tests__/unit/` (JS).
- Integration tests: `tests/Feature/` (PHP), `tests/integration/` (Python), `__tests__/integration/` (JS).
- E2E tests: `tests/E2E/` (PHP), `tests/e2e/` (Python), `__tests__/e2e/` (JS).

### 2.2 Naming
- Test class names must reflect the class under test (e.g., `PaymentServiceTest`).
- Test methods should describe behavior: `it_throws_exception_when_payment_fails()`, `testProcessPaymentWithValidData()`.

### 2.3 Arrange-Act-Assert (AAA)
- Structure each test in three clear sections:
    1. **Arrange**: Set up fixtures, mocks, and data.
    2. **Act**: Execute the method under test.
    3. **Assert**: Verify the expected outcomes.

**Example (PHPUnit):**

    public function test_calculates_total_with_tax()
    {
        // Arrange
        $cart = new Cart();
        $cart->addItem(new Item('Laptop', 1000, 1));
        $taxRate = 0.20;

        // Act
        $total = $cart->calculateTotalWithTax($taxRate);

        // Assert
        $this->assertEquals(1200, $total);
    }

---

## 3. Mocking & Test Doubles

### 3.1 When to Mock
- External services (payment gateways, APIs, email providers).
- Database interactions (unit tests only).
- Time-dependent operations (use a fixed timestamp).
- File system operations.

### 3.2 When to Use Real Implementations
- Integration tests: use real database, real cache with test configuration.
- E2E tests: use a complete staging environment.

### 3.3 Mocking Guidelines
- Mock only the immediate dependency (not the entire system).
- Verify that mocks are called with the expected parameters.
- Never mock what you don't own (e.g., a PSR interface is OK to mock).

**Example (Laravel Mockery):**

    $paymentGateway = Mockery::mock(PaymentGatewayInterface::class);
    $paymentGateway->shouldReceive('charge')
        ->once()
        ->with(100, 'token_123')
        ->andReturn(true);

    $service = new PaymentService($paymentGateway);
    $result = $service->processPayment(100, 'token_123');

    $this->assertTrue($result);

---

## 4. Test Data Management

### 4.1 Database
- Use transactions or database refreshes to ensure test isolation.
- Use factories or fixtures to generate test data.
- Avoid hardcoding IDs; generate them dynamically.

**Example (Laravel Factories):**

    $user = User::factory()->create();
    $order = Order::factory()->for($user)->create();

### 4.2 Fixtures
- Define fixtures in YAML, JSON, or factory files.
- Keep fixtures minimal and focused on the test scenario.

### 4.3 Parameterized Testing
- Use data providers or parameterized tests to reduce duplication.
- Test multiple inputs with the same logic.

**Example (PHPUnit Data Provider):**

    /**
     * @dataProvider emailValidationProvider
     */
    public function test_validates_email($email, $expected)
    {
        $this->assertEquals($expected, Validator::isValidEmail($email));
    }

    public function emailValidationProvider()
    {
        return [
            ['user@example.com', true],
            ['invalid-email', false],
            ['', false],
            ['user@domain', true],
        ];
    }

---

## 5. Assertions & Verifications

### 5.1 Assertions to Use
- `assertEquals` for value equality.
- `assertTrue` / `assertFalse` for booleans.
- `assertNull` / `assertNotNull` for null checks.
- `assertInstanceOf` for type validation.
- `assertException` or `expectException` for error scenarios.

### 5.2 Assertions to Avoid
- Avoid broad assertions like `assertTrue(true)`.
- Avoid testing multiple behaviors in one assertion.
- Never use `@cover` annotations; rely on coverage reports.

---

## 6. Performance & Execution

### 6.1 Speed
- Unit tests must run in milliseconds.
- Integration tests can take seconds but should be optimized.
- E2E tests should run in under 5 minutes.

### 6.2 Parallelization
- Run tests in parallel where possible.
- Use sharding or split tests by category.

### 6.3 CI/CD Integration
- Tests must run on every pull request.
- Coverage reports must be generated and published.
- Coverage threshold of 80% minimum; 100% for critical paths.

---

## 7. Language-Specific Rules

### 7.1 PHP / Laravel (Pest / PHPUnit)
- Use `RefreshDatabase` trait to reset database state.
- Use `LazyLoading` check to detect N+1 queries.
- Use `@dataProvider` for parameterized tests.
- Use `withoutExceptionHandling()` for debugging.

### 7.2 Python / FastAPI (pytest)
- Use `pytest-asyncio` for async fixtures.
- Use `pytest-fixtures` for dependency injection.
- Use `pytest-cov` for coverage reports.

### 7.3 JavaScript / Node (Jest)
- Use `describe` / `it` for test grouping.
- Use `jest.mock()` for module mocking.
- Use `expect` assertions with matchers.

---

## 8. Test Quality Assessment Criteria

When reviewing tests, evaluate:

1. **Atomicity**: Does each test verify exactly one behavior?
2. **Independence**: Can tests run in any order without breaking?
3. **Clarity**: Are expectations and setup easy to understand?
4. **Edge Coverage**: Are null, empty, boundary, and exceptional cases tested?
5. **Mocking Quality**: Are mocks properly stubbed and verified?
6. **Regression Protection**: Would this test catch a common bug?

---

## 9. Definition of Done (Test-Specific)

A testing task is complete when:

    - [ ] All new code has corresponding unit tests (100% line/branch/function coverage).
    - [ ] Integration tests exist for all external service interactions.
    - [ ] E2E tests exist for critical user journeys.
    - [ ] All tests pass with zero errors, warnings, or deprecations.
    - [ ] Coverage report shows green for all target files.
    - [ ] Tests run in under 30 seconds (unit) and under 2 minutes (integration).
    - [ ] No flaky tests are present (tests that fail intermittently).

---

## References

- Test-Driven Development (Kent Beck)
- The Test Pyramid (Mike Cohn)
- OWASP Testing Guide
- PHPUnit / Pest Documentation
- pytest Documentation
- Jest Documentation

---

*This skill is mandatory for all code generation and review operations. Zero exceptions.*
