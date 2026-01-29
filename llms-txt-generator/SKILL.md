---
name: llms-txt-generator
description: Generates structured llms.txt documentation files from official library/framework documentation URLs. This skill should be used when users need to create standardized, LLM-optimized reference documentation for dependencies, libraries, or frameworks they're working with.
---

# LLMs.txt Documentation Generator

This skill generates structured llms.txt documentation files from official library and framework documentation URLs. It creates standardized, LLM-optimized reference files that can be used across conversations for consistent dependency knowledge.

## When to Use This Skill

Use this skill when:
- User requests llms.txt file generation for a library, framework, or API
- User provides documentation URL(s) and asks for structured documentation
- User mentions needing dependency documentation in a standardized format
- User asks to "document" or "create docs for" a specific library with a URL

Do not use this skill for:
- General web searches about libraries
- Code generation without documentation needs
- User's own custom documentation (not from official sources)

## Documentation Retrieval Protocol

**CRITICAL**: This skill requires fetching exact URL content, not search results.

### Fetching Process

1. **Identify the URL fetching capability** in the current environment
   - Common tool names: web_fetch, fetch_url, get_page, retrieve_url
   - Look for tools that can retrieve complete page content from exact URLs

2. **Use that tool to retrieve the EXACT URL** provided by the user
   - Never substitute with web search
   - Never use search results as a proxy for actual documentation

3. **If the environment defaults to search** or lacks fetching capability:
   - Inform the user: "This environment cannot fetch exact URLs. I need direct page access to generate accurate llms.txt files."
   - Request alternative approach (manual content paste, different environment, etc.)

### Validation

Before processing retrieved content, confirm:
- ✓ Content is from the actual documentation page (check page structure, headings)
- ✓ Contains complete information with API references, code examples, or usage patterns
- ✓ URL in response matches the requested URL
- ✗ Content is NOT search engine snippets or results
- ✗ Content is NOT "Page not found", error pages, or truncated previews

If validation fails, inform the user and request the correct URL or clarification.

## When URLs Are Missing

If the user requests llms.txt generation without providing URL(s):

1. Ask the user to provide the official documentation URL(s)
2. Explain that official documentation URLs are needed for accurate extraction
3. Example response: "I'll need the official documentation URL for [library]. Please provide the link so I can generate accurate llms.txt documentation."

Do not proceed with search-based alternatives without explicit user consent.

## Standard llms.txt Structure

Generate llms.txt files following this template structure (see `references/llms-template.md` for full template):

### Required Sections

1. **Header Block**
   - Library/Framework name
   - Version (if specified in docs or URL)
   - Official documentation source URL
   - Generation date

2. **Overview**
   - Brief description (2-3 sentences)
   - Primary use case
   - Key features

3. **Installation & Setup**
   - Installation commands
   - Basic configuration
   - Peer dependencies (if applicable)

4. **Core Concepts**
   - Main abstractions or patterns
   - Architecture overview
   - Key terminology

5. **API Reference**
   - Main functions/methods/components
   - Parameters and return types
   - TypeScript types (if applicable)

6. **Common Usage Patterns**
   - Practical code examples
   - Frequent use cases
   - Integration patterns

7. **Error Handling**
   - Common errors
   - Error handling patterns
   - Debugging tips

8. **Best Practices**
   - Recommended patterns
   - Performance considerations
   - Common pitfalls to avoid

### Optional Sections (include if present in documentation)

- Authentication/Authorization
- Advanced Features
- Migration Guides
- Framework-Specific Integration (e.g., React, Vue, Node.js)

## Processing Multiple URLs

When user provides multiple URLs for the same library:

1. Fetch all provided URLs
2. Synthesize information into a single coherent llms.txt file
3. Avoid duplication - merge overlapping content
4. Maintain logical section flow from the template

When user provides URLs for different libraries:

1. Generate separate llms.txt files for each library
2. Name files clearly: `[library-name].llms.txt`
3. Present all files to the user
4. Offer to create them as separate artifacts if requested

## Extraction Guidelines

### Content Quality

- **Prioritize official examples** over third-party code
- **Include working code snippets** that demonstrate actual usage
- **Preserve TypeScript types** exactly as documented
- **Keep examples concise** but functional (5-15 lines typically)
- **Extract API signatures** with parameter types and return types

### What to Include

- Installation commands and setup steps
- Core API methods, functions, or components
- Type definitions and interfaces
- Configuration options
- Practical usage examples
- Error handling patterns
- Common integration scenarios

### What to Exclude

- Marketing copy and promotional language
- Excessive background/history
- Changelog details
- Contributor information
- Overly verbose explanations (condense to essentials)
- Deprecated APIs (unless specifically requested)

## Output Format

### File Naming

Use kebab-case: `library-name.llms.txt`

Examples:
- `stripe-api.llms.txt`
- `react-query.llms.txt`
- `tanstack-table.llms.txt`

### File Structure

```
# Library Name

**Version:** X.X.X
**Source:** [Official Documentation URL]
**Generated:** YYYY-MM-DD

## Overview
[Content]

## Installation & Setup
[Content]

[... remaining sections ...]
```

### Presentation

After generation:
1. Present the complete llms.txt file to the user
2. Confirm the file meets their needs
3. Offer to:
   - Adjust the level of detail
   - Add/remove sections
   - Generate additional llms.txt files for other dependencies
   - Explain how to use the file in their workflow

## Context-Aware Generation

### Framework Detection

Detect the framework/context from the documentation URL and adjust structure:

- **React libraries**: Emphasize component usage, hooks, props
- **Node.js libraries**: Emphasize server-side usage, async patterns, middleware
- **API services**: Emphasize authentication, endpoints, request/response formats
- **Build tools**: Emphasize configuration, plugins, optimization

### Detail Level

Default to **comprehensive** documentation that includes:
- Complete API surface
- Multiple usage examples per section
- Type definitions
- Configuration options

If user requests **concise** format:
- Focus on most common APIs (80/20 rule)
- One example per major feature
- Minimal configuration details
- Skip advanced features

## Quality Assurance

Before presenting the final llms.txt file, verify:

1. **Completeness**: All major API features are documented
2. **Accuracy**: Information matches the official documentation
3. **Functionality**: Code examples are syntactically correct
4. **Coherence**: Sections flow logically
5. **Consistency**: Formatting is uniform throughout
6. **Source attribution**: Original documentation URL is referenced

## Example Usage Flow

**User**: "Generate llms.txt for Stripe API from https://stripe.com/docs/api"

**Response**:
1. Fetch https://stripe.com/docs/api
2. Validate content is official Stripe API documentation
3. Extract according to template structure
4. Generate `stripe-api.llms.txt` with all sections
5. Present to user with confirmation prompt

**User**: "Create docs for React Query, here's the link: https://tanstack.com/query/latest"

**Response**:
1. Fetch the URL
2. Detect this is a React library
3. Emphasize hooks, component patterns
4. Generate `react-query.llms.txt`
5. Present with React-specific usage examples highlighted