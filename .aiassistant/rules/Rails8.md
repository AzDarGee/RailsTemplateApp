---
apply: always
---

# Ruby on Rails 8.1.1
You are an expert in Ruby on Rails, PostgreSQL, Hotwire (Turbo and Stimulus), and Bootstrap CSS.

Code Style and Structure
- Write concise, idiomatic Ruby code with accurate examples.
- Follow Rails conventions and best practices.
- Use object-oriented and functional programming patterns as appropriate.
- Prefer iteration and modularization over code duplication.
- Use descriptive variable and method names (e.g., user_signed_in?, calculate_total).
- Structure files according to Rails conventions (MVC, concerns, helpers, etc.).
- Any styling should be done in the assets/stylesheets folder.
- Don't put any controller logic in the views.

Documentation for reference
- Bootstrap 5.3 Docs (https://getbootstrap.com/docs/5.3/getting-started/introduction/)
- FontAwesome 6 Docs (https://docs.fontawesome.com/v6/web)
- Turbo Handbook (https://turbo.hotwired.dev/handbook/introduction)
- TurboStreams (https://turbo.hotwired.dev/reference/streams)
- StimulusJS Handbook (https://stimulus.hotwired.dev/handbook/introduction)
- StimulusJS Reference (https://stimulus.hotwired.dev/reference/controllers)

Naming Conventions
- Use snake_case for file names, method names, and variables.
- Use CamelCase for class and module names.
- Follow Rails naming conventions for models, controllers, and views.

Ruby and Rails Usage
- Use Ruby 3.x features when appropriate (e.g., pattern matching, endless methods).
- Leverage Rails' built-in helpers and methods.
- Use ActiveRecord effectively for database operations.

Syntax and Formatting
- Follow the Ruby Style Guide (https://rubystyle.guide/)
- Use Ruby's expressive syntax (e.g., unless, ||=, &.)
- Prefer single quotes for strings unless interpolation is needed.

Error Handling and Validation
- Use exceptions for exceptional cases, not for control flow.
- Implement proper error logging and user-friendly messages.
- Use ActiveModel validations in models.
- Handle errors gracefully in controllers and display appropriate flash messages.

UI and Styling
- Use Hotwire (Turbo and Stimulus) for dynamic, SPA-like interactions.
- Implement responsive design with Bootstrap 5 CSS.
- Use Rails view helpers and partials to keep views DRY.

Performance Optimization
- Use database indexing effectively.
- Implement caching strategies (fragment caching, Russian Doll caching).
- Use eager loading to avoid N+1 queries.
- Optimize database queries using includes, joins, or select.

Key Conventions
- Follow RESTful routing conventions.
- Use concerns for shared behavior across models or controllers.
- Implement service objects for complex business logic.
- Use background jobs (e.g., ActiveJob) for time-consuming tasks.

Testing
- Write comprehensive tests using RSpec or Minitest.
- Follow TDD/BDD practices.
- Use factories (FactoryBot) for test data generation.

Security
- Implemented proper authentication and authorization (e.g., Devise).
- Use strong parameters in controllers.
- Protect against common web vulnerabilities (XSS, CSRF, SQL injection).

Follow the official Ruby on Rails guides for best practices in routing, controllers, models, views, and other Rails components.

# Testing

When generating RSpec tests, follow these best practices to ensure they are comprehensive, readable, and maintainable:

### Comprehensive Coverage:
- Tests must cover both typical cases and edge cases, including invalid inputs and error conditions.
- Consider all possible scenarios for each method or behavior and ensure they are tested.

### Readability and Clarity:
- Use clear and descriptive names for describe, context, and it blocks.
- Prefer the expect syntax for assertions to improve readability.
- Keep test code concise; avoid unnecessary complexity or duplication.

### Structure:
- Organize tests logically using describe for classes/modules and context for different scenarios.
- Use subject to define the object under test when appropriate to avoid repetition.
- Ensure test file paths mirror the structure of the files being tested, but within the spec directory (e.g., app/models/user.rb → spec/models/user_spec.rb).

## Test Data Management:
- Use let and let! to define test data, ensuring minimal and necessary setup.
- Prefer factories (e.g., FactoryBot) over fixtures for creating test data.

## Independence and Isolation:
- Ensure each test is independent; avoid shared state between tests.
- Use mocks to simulate calls to external services (APIs, databases) and stubs to return predefined values for specific methods. Isolate the unit being tested, but avoid over-mocking; test real behavior when possible.

## Avoid Repetition:
- Use shared examples for common behaviors across different contexts.
- Refactor repetitive test code into helpers or custom matchers if necessary.

## Prioritize for New Developers:
- Write tests that are easy to understand, with clear intentions and minimal assumptions about the codebase.
- Include comments or descriptions where the logic being tested is complex to aid understanding.