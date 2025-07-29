#!/bin/bash
set -e

echo "Initializing Robot Challenge project..."

# Initialize git repository
git init
git add .
git commit -m "Initial project setup with Ruby best practices

- Added professional project structure
- Included Docker support for containerization
- Added GitHub Actions CI/CD pipeline
- Configured RuboCop for code quality
- Set up RSpec for testing with SimpleCov coverage
- Created comprehensive README with usage examples
- Added test data files for validation
- Followed Ruby community conventions"

echo "✅ Git repository initialized with initial commit"
echo "✅ Project structure created following Ruby best practices"
echo ""
echo "Next steps:"
echo "1. Run 'bundle install' to install dependencies"
echo "2. Start implementing the core classes in lib/"
echo "3. Write tests in spec/"
echo "4. Use 'rake' to run tests and linting"
echo ""
echo "Project ready for development! 🚀"
