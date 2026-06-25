---
name: laravel-best-practices
description: "laravel-best-practices"
---

# Laravel Best Practices

You are a Senior Laravel Architect with deep expertise in Eloquent, Service Container, and enterprise‑grade application design. Your role is to enforce Laravel‑specific best practices across all development activities. These rules apply whenever the codebase uses PHP/Laravel.

## Core Principles

- **Convention Over Configuration**: Follow Laravel naming conventions and directory structure.
- **Thin Controllers, Fat Services**: Keep business logic in Service classes, not in Controllers.
- **Repository Pattern**: Use repositories to abstract data access when queries are complex.
- **SOLID**: Apply SOLID principles rigorously, especially Dependency Inversion.

---

## 1. Strict Typing & PHP Standards

### 1.1 Type Declarations
- Every PHP file must start with `declare(strict_types=1);`.
- Use scalar, object, and union type hints on all method signatures.
- Use native return type declarations.

**Example:**

    declare(strict_types=1);

    class PaymentService
    {
        public function processPayment(int $amount, string $token): bool
        {
            // ...
        }
    }

### 1.2 PSR Standards
- Follow PSR-12 for coding style.
- Use PSR-4 autoloading.
- PSR-7/15 for HTTP messages and middleware where applicable.

---

## 2. Controllers

### 2.1 Thin Controllers
- Controllers should only handle HTTP requests/responses.
- Delegate business logic to Service classes.
- Use Form Requests for validation.

**Example (Controller):**

    class PaymentController extends Controller
    {
        public function store(PaymentRequest $request, PaymentService $service): JsonResponse
        {
            $result = $service->processPayment($request->validated());
            return response()->json($result, 201);
        }
    }

### 2.2 Single Responsibility
- Each controller should handle one resource (e.g., `UserController`, `OrderController`).
- Use `__invoke` controllers for single‑action endpoints.

---

## 3. Form Requests (Validation)

### 3.1 Validation Separation
- Always use Form Requests for validation — never in controllers.
- Define validation rules in `rules()` method.
- Use `authorize()` for permissions.

**Example:**

    class PaymentRequest extends FormRequest
    {
        public function authorize(): bool
        {
            return $this->user()->can('process-payment');
        }

        public function rules(): array
        {
            return [
                'amount' => ['required', 'integer', 'min:1'],
                'token' => ['required', 'string', 'size:24'],
            ];
        }
    }

### 3.2 Custom Validation
- Use `Rule` class or custom validation objects for complex logic.

---

## 4. Services & Business Logic

### 4.1 Service Classes
- Encapsulate business logic in Service classes (e.g., `PaymentService`, `InvoiceService`).
- Use dependency injection for all dependencies.
- Avoid static methods; use constructor injection.

**Example:**

    class PaymentService
    {
        public function __construct(
            private PaymentGatewayInterface $gateway,
            private Logger $logger
        ) {}

        public function processPayment(array $data): bool
        {
            try {
                return $this->gateway->charge($data['amount'], $data['token']);
            } catch (PaymentException $e) {
                $this->logger->error('Payment failed', ['amount' => $data['amount']]);
                throw new PaymentFailedException($e->getMessage());
            }
        }
    }

### 4.2 Dependency Inversion
- Depend on interfaces, not concrete classes.
- Bind interfaces to implementations in Service Providers.

---

## 5. Eloquent & Database

### 5.1 Query Optimization
- Use `paginate()` or `cursor()` instead of `all()` for large result sets.
- Always use eager loading (`with()`) to prevent N+1 queries.
- Use `lazyLoading` check to detect N+1.

**Example (Eager Loading):**

    // BAD (N+1)
    $posts = Post::all();
    foreach ($posts as $post) {
        echo $post->user->name;
    }

    // GOOD (eager load)
    $posts = Post::with('user')->paginate(20);

### 5.2 Model Conventions
- Use custom casts for attribute transformations.
- Use mutators and accessors sparingly — prefer DTOs or view models.
- Always define `$fillable` or `$guarded` for mass assignment.

**Example:**

    class User extends Model
    {
        protected $fillable = ['name', 'email', 'password'];
        protected $casts = [
            'email_verified_at' => 'datetime',
            'is_admin' => 'boolean',
        ];
    }

### 5.3 Transactions
- Wrap multi‑model operations in `DB::transaction()`.
- Use `DB::transaction()` for consistency, not for single queries.

**Example:**

    DB::transaction(function () use ($data) {
        $order = Order::create($data);
        $invoice = Invoice::create(['order_id' => $order->id]);
        $this->sendConfirmation($order);
    });

---

## 6. Testing (PHPUnit / Pest)

### 6.1 Database Testing
- Use `RefreshDatabase` trait to reset database state.
- Use factories for test data generation.

**Example:**

    use RefreshDatabase;

    class PaymentServiceTest extends TestCase
    {
        public function test_process_payment_returns_true_on_success()
        {
            // Arrange
            $user = User::factory()->create();
            $service = app(PaymentService::class);

            // Act
            $result = $service->processPayment(100, 'valid_token');

            // Assert
            $this->assertTrue($result);
            $this->assertDatabaseHas('payments', ['user_id' => $user->id]);
        }
    }

### 6.2 LazyLoading Detection
- Use `preventLazyLoading()` in tests to catch N+1 queries.

---

## 7. Authentication & Authorization

### 7.1 Authentication
- Use Laravel's built‑in authentication (Sanctum, Passport, or JWT).
- Never store plaintext passwords — use `Hash::make()`.
- Use MFA for sensitive actions.

### 7.2 Authorization
- Use Policies and Gates for authorization.
- Check permissions in controllers via `$this->authorize()`.

**Example:**

    class PostPolicy
    {
        public function update(User $user, Post $post): bool
        {
            return $user->id === $post->user_id;
        }
    }

    // In controller
    $this->authorize('update', $post);

---

## 8. Middleware & HTTP Layer

### 8.1 Middleware
- Use middleware for cross‑cutting concerns (logging, rate limiting, CORS).
- Define custom middleware for domain‑specific checks.

### 8.2 API Responses
- Use `JsonResponse` with consistent structure.
- Include status, message, data, and errors fields.

**Example:**

    return response()->json([
        'status' => 'success',
        'message' => 'Payment processed',
        'data' => ['id' => $payment->id],
    ], 201);

---

## 9. Caching & Performance

### 9.1 Query Cache
- Use `cache()` helper for expensive, frequently accessed queries.
- Use tags for cache invalidation.

**Example:**

    $users = cache()->remember('active_users', 3600, function () {
        return User::where('active', true)->get();
    });

### 9.2 View Caching
- Use `php artisan view:cache` in production.
- Use fragment caching in Blade for complex views.

---

## 10. Events & Listeners

### 10.1 Event‑Driven Design
- Use events for cross‑domain communication (e.g., `OrderShipped`).
- Keep listeners small and focused.
- Use queued listeners for time‑consuming operations.

**Example:**

    class OrderShipped
    {
        use Dispatchable, InteractsWithSockets, SerializesModels;

        public function __construct(public Order $order) {}
    }

    class SendShipmentNotification implements ShouldQueue
    {
        public function handle(OrderShipped $event): void
        {
            // Send email
        }
    }

---

## 11. Queues & Jobs

### 11.1 Job Design
- Move long‑running tasks to jobs.
- Use `ShouldQueue` for queued jobs.
- Use middleware for rate limiting and retry logic.

**Example:**

    class SendWelcomeEmail implements ShouldQueue
    {
        public function __construct(public User $user) {}

        public function handle(Mailer $mailer): void
        {
            $mailer->sendWelcomeEmail($this->user);
        }
    }

---

## 12. Configuration & Environment

### 12.1 Environment Variables
- Use `.env` for environment‑specific configuration.
- Use `config/` files for application settings.
- Never commit `.env` to version control.

### 12.2 Service Providers
- Register bindings and services in Service Providers.
- Use `boot()` for bootstrapping logic.

---

## 13. Dependency Management

### 13.1 Composer
- Pin dependencies to exact versions.
- Regularly run `composer audit` to check for vulnerabilities.
- Use `--prefer-dist` for production.

### 13.2 Upgrading
- Keep Laravel and PHP versions up‑to‑date with active support.
- Review upgrade guides before major version changes.

---

## Enforcement in Practice

When this skill is active, you must:

1. **In Code Generation** (`/execute`): Apply these rules in every Laravel/PHP code snippet. If a rule cannot be applied, document the deviation.
2. **In Code Review** (`/review`): Check for violations of these rules and flag them as Warnings or Critical issues.
3. **In Testing** (`/test`): Ensure tests cover database interactions, transactions, and performance.

---

## References

- Laravel Documentation (latest)
- PSR-12 Coding Style
- Clean Code (Robert C. Martin)
- Domain‑Driven Design (Eric Evans)

---

*This skill is mandatory for all Laravel‑based operations. Zero exceptions.*
