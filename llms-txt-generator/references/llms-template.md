# LLMs.txt Template Structure

This template provides the standard structure for generated llms.txt files. Use this as a guide when extracting and organizing documentation content.

---

## Template: Standard Library/Framework

```markdown
# [Library/Framework Name]

**Version:** [X.X.X or "Latest" if not specified]
**Source:** [Official Documentation URL]
**Generated:** [YYYY-MM-DD]

## Overview

[2-3 sentence description of what the library does]

**Primary Use Case:** [Main purpose in one sentence]

**Key Features:**
- [Feature 1]
- [Feature 2]
- [Feature 3]

## Installation & Setup

### Installation

```bash
[Installation command, e.g., npm install package-name]
```

### Basic Setup

```[language]
[Minimal setup code example]
```

**Configuration Options:**
- `option1`: [Description]
- `option2`: [Description]

**Peer Dependencies:**
- [If applicable, list required peer dependencies]

## Core Concepts

### [Concept 1]

[Brief explanation of main abstraction or pattern]

### [Concept 2]

[Brief explanation of second major concept]

**Key Terminology:**
- **Term1**: [Definition]
- **Term2**: [Definition]

## API Reference

### [Primary Function/Component/Method]

```[language]
[Function signature with types]
```

**Parameters:**
- `param1` ([type]): [Description]
- `param2` ([type]): [Description]

**Returns:** [Return type and description]

**Example:**
```[language]
[Working code example]
```

### [Secondary Function/Component/Method]

[Repeat structure above for each major API]

## Common Usage Patterns

### [Pattern 1: Use Case Name]

[Brief explanation of when to use this pattern]

```[language]
[Code example demonstrating the pattern]
```

### [Pattern 2: Use Case Name]

[Brief explanation]

```[language]
[Code example]
```

## Error Handling

### Common Errors

**[Error Type 1]**
```[language]
[Example of error]
```
**Solution:** [How to handle or prevent]

**[Error Type 2]**
```[language]
[Example of error]
```
**Solution:** [How to handle or prevent]

### Error Handling Pattern

```[language]
[Recommended error handling approach with code]
```

## Best Practices

### Recommended Patterns

- **[Practice 1]**: [Explanation and why it's recommended]
- **[Practice 2]**: [Explanation]
- **[Practice 3]**: [Explanation]

### Performance Considerations

- [Performance tip 1]
- [Performance tip 2]

### Common Pitfalls

- ❌ **[Pitfall 1]**: [What to avoid and why]
- ✓ **Better approach**: [How to do it correctly]

---

## Optional Sections (Include if Present in Documentation)

### Authentication

[If applicable - API keys, OAuth, etc.]

```[language]
[Authentication setup example]
```

### Advanced Features

#### [Advanced Feature 1]

[Description and example]

#### [Advanced Feature 2]

[Description and example]

### Framework Integration

#### React Integration

[If applicable - specific React usage]

```jsx
[React-specific example]
```

#### [Other Framework]

[Framework-specific guidance if documented]

### Migration Guide

**From [Old Version] to [New Version]:**
- [Breaking change 1]
- [Breaking change 2]

```[language]
// Before
[Old code]

// After  
[New code]
```

### TypeScript Types

```typescript
// Core types
[Key type definitions from the library]

// Usage example
[Example showing type usage]
```
```

---

## Template: API Service

```markdown
# [API Service Name]

**Version:** [API version]
**Source:** [Official API Documentation URL]
**Generated:** [YYYY-MM-DD]
**Base URL:** [https://api.example.com]

## Overview

[Description of the API service]

**Authentication:** [Auth method used]

## Authentication

### [Auth Method - e.g., API Keys]

```bash
[How to authenticate]
```

**Headers:**
```
Authorization: Bearer [token]
Content-Type: application/json
```

## Endpoints

### [Endpoint Category 1]

#### [HTTP METHOD] /endpoint/path

[Description of what this endpoint does]

**Request:**
```json
{
  "param1": "value",
  "param2": "value"
}
```

**Response:**
```json
{
  "status": "success",
  "data": {}
}
```

**Query Parameters:**
- `param1` (string): [Description]
- `param2` (number, optional): [Description]

**Example:**
```bash
curl -X POST https://api.example.com/endpoint \
  -H "Authorization: Bearer TOKEN" \
  -d '{"param1": "value"}'
```

### [Endpoint Category 2]

[Repeat structure for other endpoints]

## Error Codes

| Code | Meaning | Resolution |
|------|---------|------------|
| 400  | Bad Request | [How to fix] |
| 401  | Unauthorized | [How to fix] |
| 404  | Not Found | [How to fix] |
| 429  | Rate Limited | [How to fix] |

## Rate Limiting

[Rate limit details]

## Webhooks

[If applicable - webhook setup and handling]

## Best Practices

- [API-specific best practices]
- [Retry logic recommendations]
- [Caching strategies]
```

---

## Template Variants Guide

### For React Libraries
- Emphasize: Components, Hooks, Props, Context
- Include: JSX examples, component composition patterns
- Add sections: "Component API", "Hook Usage", "Styling"

### For Node.js Libraries  
- Emphasize: Async patterns, middleware, server setup
- Include: Express/Fastify integration examples
- Add sections: "Middleware Usage", "Server Configuration"

### For Build Tools
- Emphasize: Configuration, plugins, optimization
- Include: Build config examples, plugin setup
- Add sections: "Configuration Options", "Plugin Development"

### For Testing Libraries
- Emphasize: Test patterns, assertions, mocking
- Include: Test examples for different scenarios
- Add sections: "Matchers", "Mock Functions", "Async Testing"

---

## Content Extraction Guidelines

### For Code Examples
- Keep examples 5-15 lines when possible
- Show complete, runnable examples
- Include necessary imports
- Comment complex parts
- Show both simple and real-world usage

### For API Documentation
- Preserve exact function signatures
- Include all parameter types
- Note optional vs required parameters
- Show return types clearly
- Include any generic type parameters

### For Configuration
- Show minimal required config
- Show common customizations
- Note default values
- Explain when to change defaults

### Condensing Content
When documentation is verbose:
- Extract the essential information
- Remove marketing language
- Condense explanations to 1-2 sentences
- Keep code examples intact
- Preserve exact API signatures and types