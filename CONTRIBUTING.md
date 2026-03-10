# Contributing to Vehicle Explorer

Thank you for your interest in contributing to Vehicle Explorer! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- Clear and descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Screenshots (if applicable)
- Environment details (OS, browser, .NET version, Node version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- Clear and descriptive title
- Detailed description of the proposed functionality
- Explain why this enhancement would be useful
- List any alternative solutions you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes following the coding standards
4. Write or update tests as needed
5. Ensure all tests pass
6. Commit your changes using conventional commits
7. Push to your fork
8. Open a Pull Request

## Development Setup

### Prerequisites

- .NET 8.0 SDK
- Node.js 18+
- Docker Desktop (optional)
- Git

### Local Development

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/vehicle-explorer.git
cd vehicle-explorer

# Backend
cd backend
dotnet restore
dotnet build
dotnet test

# Frontend
cd ../frontend
npm install
npm test
npm start
```

## Coding Standards

### Backend (.NET)

- Follow [C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Use meaningful variable and method names
- Keep methods small and focused (Single Responsibility Principle)
- Write XML documentation comments for public APIs
- Follow Clean Architecture dependency rules strictly
- Use async/await for I/O operations
- Handle exceptions appropriately

#### Example

```csharp
/// <summary>
/// Retrieves all vehicle makes from the NHTSA API
/// </summary>
/// <param name="ct">Cancellation token</param>
/// <returns>List of vehicle makes</returns>
public async Task<IReadOnlyList<Make>> GetAllMakesAsync(CancellationToken ct = default)
{
    // Implementation
}
```

### Frontend (Angular/TypeScript)

- Follow [Angular Style Guide](https://angular.io/guide/styleguide)
- Use TypeScript strict mode
- Prefer standalone components
- Use signals for reactive state when appropriate
- Use RxJS operators for complex async operations
- Keep components focused and small
- Use Angular Material components consistently

#### Example

```typescript
export class VehicleSearchComponent {
  private vehicleService = inject(VehicleService);
  
  makes = signal<Make[]>([]);
  loading = signal(false);
  
  loadMakes(): void {
    this.loading.set(true);
    this.vehicleService.getMakes()
      .subscribe({
        next: (response) => {
          this.makes.set(response.data);
          this.loading.set(false);
        },
        error: (error) => {
          console.error('Error loading makes:', error);
          this.loading.set(false);
        }
      });
  }
}
```

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(api): add caching for vehicle types endpoint

Implement caching behavior for GetVehicleTypesQuery to improve
performance for frequently accessed data.

Closes #123
```

```
fix(frontend): resolve year validation issue

Year selector now correctly validates years between 1995 and current year.

Fixes #456
```

## Testing Guidelines

### Backend Tests

- Write unit tests for all handlers and validators
- Use xUnit for test framework
- Mock external dependencies (IVehicleRepository)
- Aim for >80% code coverage

```csharp
public class GetAllMakesHandlerTests
{
    [Fact]
    public async Task Handle_ShouldReturnMakes_WhenRepositoryReturnsData()
    {
        // Arrange
        var mockRepo = new Mock<IVehicleRepository>();
        mockRepo.Setup(r => r.GetAllMakesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Make> { Make.Create(1, "Toyota") });
        
        var handler = new GetAllMakesHandler(mockRepo.Object);
        var query = new GetAllMakesQuery();
        
        // Act
        var result = await handler.Handle(query, CancellationToken.None);
        
        // Assert
        Assert.True(result.Success);
        Assert.Single(result.Data);
    }
}
```

### Frontend Tests

- Write unit tests for services and components
- Use Jasmine/Karma for testing
- Mock HTTP calls with HttpClientTestingModule

```typescript
describe('VehicleService', () => {
  let service: VehicleService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [VehicleService]
    });
    service = TestBed.inject(VehicleService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  it('should fetch makes', () => {
    const mockResponse = { success: true, data: [], count: 0 };
    
    service.getMakes().subscribe(response => {
      expect(response.success).toBe(true);
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/vehicles/makes`);
    expect(req.request.method).toBe('GET');
    req.flush(mockResponse);
  });
});
```

## Architecture Guidelines

### Clean Architecture Layers

Respect the dependency rule: dependencies point inward only.

```
Domain ← Application ← Infrastructure
                    ← API
```

- **Domain**: No dependencies on other layers
- **Application**: Depends only on Domain
- **Infrastructure**: Depends on Application (implements interfaces)
- **API**: Depends on Application and Infrastructure (composition root only)

### CQRS Pattern

- Queries: Read operations, return DTOs
- Commands: Write operations (not used in this project yet)
- Handlers: One handler per query/command
- Validators: FluentValidation for input validation

### Adding New Features

#### Backend Query

1. Create query record in `Application/Features/[Feature]/Queries/[QueryName]/`
2. Create handler implementing `IRequestHandler<TQuery, TResponse>`
3. Create validator extending `AbstractValidator<TQuery>`
4. Create DTO record for response
5. Add controller endpoint in API layer

#### Frontend Feature

1. Create feature folder in `src/app/features/[feature-name]/`
2. Create service in `services/` folder
3. Create models in `models/` folder
4. Create components in `components/` folder
5. Add routes if needed

## Documentation

- Update README.md for significant changes
- Add XML comments to public APIs
- Update API documentation (Swagger annotations)
- Include code examples for complex features

## Review Process

1. All submissions require review
2. Reviewers will check:
   - Code quality and standards
   - Test coverage
   - Documentation
   - Architecture compliance
3. Address review feedback promptly
4. Squash commits before merging (if requested)

## Release Process

1. Version follows [Semantic Versioning](https://semver.org/)
2. Update CHANGELOG.md
3. Tag release in Git
4. Deploy to staging for testing
5. Deploy to production

## Questions?

Feel free to open an issue for questions or reach out to maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
