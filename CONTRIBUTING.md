# Contributing Guide

## Branch Strategy (GitFlow)

### Branch Structure:
- **main** - Production-ready code (protected)
- **dev** - Development branch (integration)
- **feature/*** - Feature branches (from dev)

### Workflow:

#### 1. Create Feature Branch
```bash
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name
```

#### 2. Work on Feature
```bash
# Make changes
git add .
git commit -m "feat: description"
git push origin feature/your-feature-name
```

#### 3. Create Pull Request
- Create PR: feature/your-feature-name  dev
- Add description
- Link issue number
- Wait for review

#### 4. Merge to Dev
- After approval, merge to dev
- Delete feature branch

#### 5. Deploy to Production
- Create PR: dev  main
- After approval, merge to main
- GitHub Actions will deploy automatically

## Commit Message Convention

Format: \<type>: <description>\

Types:
- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation
- **style**: Code style (formatting)
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Maintenance tasks

Examples:
```
feat: add SSO authentication with AWS Cognito
fix: resolve RBAC permission issue for managers
docs: update architecture diagram with auth flow
```

## Current Features

### Active Branch:
- **feature/sso-rbac-implementation** - SSO & RBAC per department

### Next Features:
- Create new branch from dev for each feature
- Follow naming: feature/descriptive-name
